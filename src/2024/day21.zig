const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day21.txt");

var memo = Map([4]i64, u64).init(std.heap.page_allocator);

// directional pad:  " ^ A " / " < v > "  — coordinates (x, y)
fn dirPos(c: u8) [2]i32 {
    return switch (c) {
        '^' => .{ 1, 0 },
        'A' => .{ 2, 0 },
        '<' => .{ 0, 1 },
        'v' => .{ 1, 1 },
        else => .{ 2, 1 },
    };
}

// numeric pad: "789" / "456" / "123" / " 0A"
fn numPos(c: u8) [2]i32 {
    return switch (c) {
        '7' => .{ 0, 0 },
        '8' => .{ 1, 0 },
        '9' => .{ 2, 0 },
        '4' => .{ 0, 1 },
        '5' => .{ 1, 1 },
        '6' => .{ 2, 1 },
        '1' => .{ 0, 2 },
        '2' => .{ 1, 2 },
        '3' => .{ 2, 2 },
        '0' => .{ 1, 3 },
        else => .{ 2, 3 },
    };
}

/// Enumerate all orderings of |dx| H-steps and |dy| V-steps; call `step` per
/// candidate ordering as a u8 string in `buf`. Returns number of candidates.
fn eachPath(from: [2]i32, to: [2]i32, bad: [2]i32, ctx: anytype, comptime visit: anytype) void {
    const dx = to[0] - from[0];
    const dy = to[1] - from[1];
    const h: usize = @intCast(@abs(dx));
    const v: usize = @intCast(@abs(dy));
    const hd: u8 = if (dx > 0) '>' else '<';
    const vd: u8 = if (dy > 0) 'v' else '^';
    var arr: [8]u8 = undefined;
    var i: usize = 0;
    while (i < h) : (i += 1) arr[i] = hd;
    while (i < h + v) : (i += 1) arr[i] = vd;
    const n = h + v;
    // enumerate distinct permutations of arr (multiset)
    var arrs: [24][8]u8 = undefined;
    var counts: usize = 0;
    sortAndPermute(&arrs, &counts, arr[0..n]);
    var k: usize = 0;
    while (k < counts) : (k += 1) {
        const cand = arrs[k][0..n];
        // gap check along the walk
        var x = from[0];
        var y = from[1];
        var ok = true;
        for (cand) |c| {
            if (c == '>') x += 1 else if (c == '<') x -= 1 else if (c == 'v') y += 1 else y -= 1;
            if (x == bad[0] and y == bad[1]) {
                ok = false;
                break;
            }
        }
        if (ok) visit(ctx, cand);
    }
}

fn sortAndPermute(out: *[24][8]u8, counts: *usize, s: []u8) void {
    // simple distinct-permutation enumeration via next_permutation on a sorted copy
    std.mem.sort(u8, s, {}, std.sort.asc(u8));
    var buf: [8]u8 = undefined;
    @memcpy(buf[0..s.len], s);
    while (true) {
        // dedupe insert
        var dup = false;
        var k: usize = 0;
        while (k < counts.*) : (k += 1) {
            if (std.mem.eql(u8, out[k][0..s.len], buf[0..s.len])) dup = true;
        }
        if (!dup) {
            @memcpy(out[counts.*][0..s.len], buf[0..s.len]);
            counts.* += 1;
        }
        if (!nextPerm(&buf, s.len)) break;
    }
}

fn nextPerm(a: *[8]u8, n: usize) bool {
    if (n == 0) return false;
    // largest i with a[i-1] < a[i]
    var i: usize = n - 1;
    while (i > 0 and a[i - 1] >= a[i]) i -= 1;
    if (i == 0) return false;
    var k: usize = n - 1;
    while (a[k] <= a[i - 1]) k -= 1;
    std.mem.swap(u8, &a[i - 1], &a[k]);
    std.mem.reverse(u8, a[i..n]);
    return true;
}

fn dirCost(from: u8, to: u8, depth: u32) u64 {
    if (depth == 0) {
        const m = movesBetweenLen(dirPos(from), dirPos(to));
        return m;
    }
    const key = [4]i64{ from, to, @intCast(depth), 0 };
    if (memo.get(key)) |v| return v;
    const Ctx = struct {
        best: *u64,
        depth: u32,
    };
    var best: u64 = std.math.maxInt(u64);
    var ctx = Ctx{ .best = &best, .depth = depth };
    eachPath(dirPos(from), dirPos(to), .{ 0, 0 }, &ctx, struct {
        fn visit(c: *Ctx, cand: []const u8) void {
            var total: u64 = 0;
            var prev: u8 = 'A';
            for (cand) |ch| {
                total += dirCost(prev, ch, c.depth - 1);
                prev = ch;
            }
            total += dirCost(prev, 'A', c.depth - 1);
            c.best.* = @min(c.best.*, total);
        }
    }.visit);
    memo.put(key, best) catch {};
    return best;
}

fn movesBetweenLen(a: [2]i32, b: [2]i32) u64 {
    const dx = @abs(b[0] - a[0]);
    const dy = @abs(b[1] - a[1]);
    return @intCast(dx + dy + 1);
}

fn codeComplexity(depth: u32) !u64 {
    var total: u64 = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |code| {
        var c: u64 = 0;
        var prev: u8 = 'A';
        for (code) |target| {
            const Ctx = struct { best: *u64, depth: u32, prev: u8 };
            var best: u64 = std.math.maxInt(u64);
            var ctx = Ctx{ .best = &best, .depth = depth, .prev = prev };
            eachPath(numPos(prev), numPos(target), .{ 0, 3 }, &ctx, struct {
                fn visit(cc: *Ctx, cand: []const u8) void {
                    var t: u64 = 0;
                    var p: u8 = 'A';
                    for (cand) |ch| {
                        t += dirCost(p, ch, cc.depth);
                        p = ch;
                    }
                    t += dirCost(p, 'A', cc.depth);
                    cc.best.* = @min(cc.best.*, t);
                }
            }.visit);
            c += best;
            prev = target;
        }
        var num: u64 = 0;
        for (code[0..3]) |ch| {
            num = num * 10 + (ch - '0');
        }
        total += c * num;
    }
    return total;
}

pub fn main() !void {
    // depth counts directional pads ABOVE the numeric pad, where depth 0
    // is the human finger-pressing pad; validated against the canonical
    // example (2 robots -> 126384)
    print("part 1: {d}\n", .{try codeComplexity(1)});
    print("part 2: {d}\n", .{try codeComplexity(24)});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
