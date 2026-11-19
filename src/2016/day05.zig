const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day05.txt");

/// A hash with 5 leading zero hex digits: rare enough (~2^-20) to collect
/// into a shared list and reason about globally. Both parts only ever want
/// the smallest indices, so mining can stop as soon as the scanned range
/// contains enough hits — anything past it is larger.
const Hit = struct { idx: u64, c6: u8, c7: u8 };

const CHUNK = 1 << 16;

const Batch = struct {
    secret: []const u8,
    base: u64, // global index of local 0
    len: u64, // batch length in indices
    hits: []Hit,
    n_hits: *std.atomic.Value(u64), // cumulative across batches
    next: std.atomic.Value(u64) = .init(0), // local claim counter

    fn worker(self: *Batch) void {
        while (true) {
            const start = self.next.fetchAdd(CHUNK, .acq_rel);
            if (start >= self.len) return;
            var batch: u64 = 0;
            while (batch < CHUNK / 8) : (batch += 1) {
                const base = start + batch * 8;
                if (base >= self.len) return;
                var bufs: [8][64]u8 = undefined;
                var msgs: [8][]const u8 = undefined;
                for (0..8) |lane| {
                    msgs[lane] = std.fmt.bufPrint(&bufs[lane], "{s}{d}", .{ self.secret, self.base + base + lane }) catch unreachable;
                }
                var digests: [8][16]u8 = undefined;
                util.md5x4.hash8(msgs, &digests);
                for (0..8) |lane| {
                    const d = digests[lane];
                    if (d[0] != 0 or d[1] != 0 or d[2] > 0x0f) continue;
                    const slot = self.n_hits.fetchAdd(1, .acq_rel);
                    if (slot < self.hits.len) {
                        self.hits[slot] = .{
                            .idx = self.base + base + lane,
                            .c6 = hexNibble(d[2] & 0x0f),
                            .c7 = hexNibble(d[3] >> 4),
                        };
                    }
                }
            }
        }
    }
};

fn hexNibble(b: u8) u8 {
    return if (b < 10) '0' + b else 'a' + b - 10;
}

fn lessThan(_: void, a: Hit, b: Hit) bool {
    return a.idx < b.idx;
}

pub fn main() !void {
    const door = trim(u8, data, " \n\r\t");

    const n_threads = try std.Thread.getCpuCount();
    const hits = try gpa.alloc(Hit, 1 << 16);
    defer gpa.free(hits);
    var n_hits = std.atomic.Value(u64).init(0);

    // mine in doubling batches until both parts are satisfiable
    var scanned: u64 = 0;
    var batch_len: u64 = 1 << 22;
    while (true) {
        var batch = Batch{ .secret = door, .base = scanned, .len = batch_len, .hits = hits, .n_hits = &n_hits };
        var threads = try std.ArrayList(std.Thread).initCapacity(gpa, n_threads);
        defer threads.deinit(gpa);
        for (0..n_threads) |_| {
            try threads.append(gpa, try std.Thread.spawn(.{}, Batch.worker, .{&batch}));
        }
        for (threads.items) |t| t.join();

        scanned += batch_len;
        batch_len *= 2;

        const total = n_hits.load(.acquire);
        if (total > hits.len) return error.TooManyHits;
        const found = hits[0..total];
        std.mem.sort(Hit, found, {}, lessThan);

        // part 1: first 8 hits
        var password: [8]u8 = @splat('_');
        var n1: usize = 0;
        for (found) |h| {
            if (n1 == 8) break;
            password[n1] = h.c6;
            n1 += 1;
        }
        // part 2: first valid hit per position
        var p2: [8]u8 = @splat('_');
        var p2_found: u32 = 0;
        for (found) |h| {
            if (h.c6 >= '0' and h.c6 <= '7') {
                const pos: usize = h.c6 - '0';
                if (p2[pos] == '_') {
                    p2[pos] = h.c7;
                    p2_found += 1;
                }
            }
        }
        if (n1 == 8 and p2_found == 8) {
            print("part 1: {s}\n", .{password});
            print("part 2: {s}\n", .{p2});
            return;
        }
        if (scanned >= 1 << 34) return error.TooManyRounds;
    }
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
