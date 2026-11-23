const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day14.txt");

const Md5 = std.crypto.hash.Md5;

/// Per-index summary of a (possibly stretched) hash: the first triplet
/// character, if any, plus a bitmask of characters that appear in a run of
/// 5+. Precomputing these in parallel reduces the key search to a cheap
/// sequential scan.
const Rec = packed struct(u24) {
    triple: u8 = no_triple, // hex char value, or no_triple
    quints: u16 = 0, // bit c set => run of 5+ of hex char c
};
const no_triple: u8 = 0xff;

const CHUNK = 1024;

const Fill = struct {
    salt: []const u8,
    base: usize,
    len: usize,
    recs: []Rec,
    next: std.atomic.Value(u64) = .init(0),

    /// Hash eight consecutive indices through two interleaved SIMD chains —
    /// including the 2017-round stretch chain, whose 32-char hex messages
    /// are also single-block and hash 8-at-a-time.
    fn hashRecs8(self: *Fill, base: usize, stretch: bool) void {
        var bufs: [8][64]u8 = undefined;
        var msgs: [8][]const u8 = undefined;
        for (0..8) |lane| {
            msgs[lane] = std.fmt.bufPrint(&bufs[lane], "{s}{d}", .{ self.salt, base + lane }) catch unreachable;
        }
        var digests: [8][16]u8 = undefined;
        util.md5x4.hash8(msgs, &digests);
        if (stretch) {
            var round: usize = 0;
            while (round < 2016) : (round += 1) {
                var hexes: [8][32]u8 = undefined;
                for (0..8) |lane| hexes[lane] = hexOf(digests[lane]);
                for (0..8) |lane| msgs[lane] = &hexes[lane];
                util.md5x4.hash8(msgs, &digests);
            }
        }
        for (0..8) |lane| {
            const h = hexOf(digests[lane]);
            self.recs[base + lane] = summarize(&h);
        }
    }

    fn worker(self: *Fill, stretch: bool) void {
        while (true) {
            const start = self.next.fetchAdd(CHUNK, .acq_rel);
            if (start >= self.len) return;
            const lo = self.base + start;
            const hi = lo + @min(CHUNK, self.len - start);
            var idx = lo;
            while (idx + 8 <= hi) : (idx += 8) {
                self.hashRecs8(idx, stretch);
            }
            while (idx < hi) : (idx += 1) {
                // tail (never hit: lens are powers of two) — scalar fallback
                const h = self.hashOf(idx, stretch);
                self.recs[idx] = summarize(&h);
            }
        }
    }

    fn hashOf(self: *const Fill, idx: u64, stretch: bool) [32]u8 {
        var buf: [64]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "{s}{d}", .{ self.salt, idx }) catch unreachable;
        var digest: [16]u8 = undefined;
        Md5.hash(msg, &digest, .{});
        var h = hexOf(digest);
        if (stretch) {
            var round: usize = 0;
            while (round < 2016) : (round += 1) {
                Md5.hash(&h, &digest, .{});
                h = hexOf(digest);
            }
        }
        return h;
    }
};

fn hexOf(digest: [16]u8) [32]u8 {
    // nibble -> ascii via vector math (n + '0' + (n > 9) * 39), interleaved
    const v: @Vector(16, u8) = digest;
    const hi: @Vector(16, u8) = v >> @as(@Vector(16, u8), @splat(4));
    const lo: @Vector(16, u8) = v & @as(@Vector(16, u8), @splat(15));
    const hi_c = hexChar(hi);
    const lo_c = hexChar(lo);
    var out: [32]u8 = undefined;
    inline for (0..16) |i| {
        out[i * 2] = hi_c[i];
        out[i * 2 + 1] = lo_c[i];
    }
    return out;
}

fn hexChar(nib: @Vector(16, u8)) @Vector(16, u8) {
    const gt9 = nib > @as(@Vector(16, u8), @splat(9));
    const adj = @select(u8, gt9, @as(@Vector(16, u8), @splat(39)), @as(@Vector(16, u8), @splat(0)));
    return nib +% @as(@Vector(16, u8), @splat('0')) +% adj;
}

fn charVal(c: u8) u8 {
    return if (c <= '9') c - '0' else c - 'a' + 10;
}

fn summarize(h: *const [32]u8) Rec {
    var rec = Rec{};
    var run: usize = 1;
    var i: usize = 1;
    while (i <= 32) : (i += 1) {
        if (i < 32 and h[i] == h[i - 1]) {
            run += 1;
            continue;
        }
        const c = charVal(h[i - 1]);
        if (run >= 5) rec.quints |= @as(u16, 1) << @intCast(c);
        run = 1;
    }
    // triplet: first run of 3+
    run = 1;
    i = 1;
    while (i < 32) : (i += 1) {
        if (h[i] == h[i - 1]) {
            run += 1;
            if (run == 3) {
                rec.triple = charVal(h[i]);
                break;
            }
        } else {
            run = 1;
        }
    }
    return rec;
}

/// Fill recs[base..base+len) with threads.
fn fillParallel(salt: []const u8, recs: []Rec, base: usize, len: usize, stretch: bool, n_threads: usize) !void {
    var f = Fill{ .salt = salt, .base = base, .len = len, .recs = recs };
    var threads = try std.ArrayList(std.Thread).initCapacity(gpa, n_threads);
    defer threads.deinit(gpa);
    for (0..n_threads) |_| {
        try threads.append(gpa, try std.Thread.spawn(.{}, Fill.worker, .{ &f, stretch }));
    }
    for (threads.items) |t| t.join();
}

/// Scan the filled window for the index of the 64th one-time pad key.
/// Returns null if the window is too small (a triplet's 1000-index quint
/// lookahead got truncated, or 64 keys simply don't fit yet).
fn scanKeys(recs: []const Rec) ?usize {
    var keys: u32 = 0;
    for (recs, 0..) |rec, i| {
        if (rec.triple == no_triple) continue;
        const bit = @as(u16, 1) << @intCast(rec.triple);
        const hi = @min(i + 1000, recs.len - 1);
        if (hi < i + 1000) return null; // truncated lookahead: inconclusive
        for (recs[i + 1 .. hi + 1]) |r2| {
            if (r2.quints & bit != 0) {
                keys += 1;
                break;
            }
        }
        if (keys == 64) return i;
    }
    return null;
}

fn findKey(salt: []const u8, stretch: bool, n_threads: usize) !u64 {
    var window: usize = 1 << 15;
    var recs = try gpa.alloc(Rec, window);
    defer gpa.free(recs);
    var filled: usize = 0;
    while (true) {
        try fillParallel(salt, recs, filled, window - filled, stretch, n_threads);
        filled = window;
        if (scanKeys(recs)) |k| return k;
        window = (window * 3 / 2 + 3) & ~@as(usize, 3);
        recs = try gpa.realloc(recs, window);
    }
}

pub fn main() !void {
    const salt = trim(u8, data, " \n\r\t");
    const n_threads = try std.Thread.getCpuCount();
    print("part 1: {d}\n", .{try findKey(salt, false, n_threads)});
    print("part 2: {d}\n", .{try findKey(salt, true, n_threads)});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
