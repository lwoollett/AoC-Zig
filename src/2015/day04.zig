const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day04.txt");

/// Parallel md5 prefix-mining: one sweep finds the lowest nonce with 5
/// leading zero hex digits (part 1) and with 6 (part 2). Workers claim
/// 4-index batches from an atomic counter (each batch hashes 4 nonces in
/// SIMD lanes via util.md5x4); a stop flag halts new claims once a 6-zero
/// hit exists (every lower batch is already claimed, so in-flight batches
/// still finish and the minimums stay exact).
const STRIDE = 8192; // nonces per atomic claim (amortizes fetchAdd contention)

const Mine = struct {
    secret: []const u8,
    next: std.atomic.Value(u64) = .init(0), // counts nonces in STRIDE steps
    stop: std.atomic.Value(bool) = .init(false),
    best5: std.atomic.Value(u64) = .init(std.math.maxInt(u64)),
    best6: std.atomic.Value(u64) = .init(std.math.maxInt(u64)),

    fn worker(self: *Mine) void {
        outer: while (!self.stop.load(.acquire)) {
            const claim = self.next.fetchAdd(STRIDE, .acq_rel);
            var batch: u64 = 0;
            while (batch < STRIDE / 8) : (batch += 1) {
                const base = claim + batch * 8;
                var bufs: [8][64]u8 = undefined;
                var msgs: [8][]const u8 = undefined;
                for (0..8) |lane| {
                    msgs[lane] = std.fmt.bufPrint(&bufs[lane], "{s}{d}", .{ self.secret, base + lane }) catch unreachable;
                }
                var digests: [8][16]u8 = undefined;
                util.md5x4.hash8(msgs, &digests);
                for (0..8) |lane| {
                    const d = digests[lane];
                    if (d[0] != 0 or d[1] != 0) continue;
                    const nonce = base + lane;
                    if (d[2] == 0) {
                        // 6+ zero hex digits (also qualifies for 5)
                        _ = self.best6.fetchMin(nonce, .acq_rel);
                        _ = self.best5.fetchMin(nonce, .acq_rel);
                        self.stop.store(true, .release);
                        continue :outer; // remaining nonces in this claim are larger
                    }
                    if (d[2] <= 0x0f) {
                        _ = self.best5.fetchMin(nonce, .acq_rel);
                    }
                }
            }
        }
    }
};

pub fn main() !void {
    const secret = trim(u8, data, " \n\r\t");

    var mine = Mine{ .secret = secret };
    const n_threads = try std.Thread.getCpuCount();
    var threads = try std.ArrayList(std.Thread).initCapacity(gpa, n_threads);
    defer threads.deinit(gpa);
    for (0..n_threads) |_| {
        try threads.append(gpa, try std.Thread.spawn(.{}, Mine.worker, .{&mine}));
    }
    for (threads.items) |t| t.join();

    print("part 1: {d}\n", .{mine.best5.load(.acquire)});
    print("part 2: {d}\n", .{mine.best6.load(.acquire)});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
