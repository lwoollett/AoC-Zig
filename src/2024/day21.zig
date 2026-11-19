const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day21.txt");

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

fn movesBetween(a: [2]i32, b: [2]i32, bad: ?[2]i32) struct { h: u32, v: u32, dir_h: i32, dir_v: i32, ok_hv: bool, ok_vh: bool } {
    const dx = b[0] - a[0];
    const dy = b[1] - a[1];
    const dir_h: i32 = if (dx > 0) 1 else -1;
    const dir_v: i32 = if (dy > 0) 1 else -1;
    const n_h: u32 = @intCast(@abs(dx));
    const n_v: u32 = @intCast(@abs(dy));
    // path validity: H-then-V passes (a + dx, a.y); V-then-H passes (a.x, a.y+dy)
    var ok_hv = true;
    var ok_vh = true;
    if (bad) |bd| {
        // HV: after horizontal we are at (b.x, a.y)
        if (b[0] == bd[0] and a[1] == bd[1]) ok_hv = false;
        // VH: after vertical we are at (a.x, b.y)
        if (a[0] == bd[0] and b[1] == bd[1]) ok_vh = false;
    }
    return .{ .h = n_h, .v = n_v, .dir_h = dir_h, .dir_v = dir_v, .ok_hv = ok_hv, .ok_vh = ok_vh };
}

/// cost of typing sequence `seq` with `depth` robots above (depth counts the
/// directional robots; the top human contributes length directly)
var memo = Map([4]i64, u64).init(std.heap.page_allocator);

fn dirCost(from: u8, to: u8, depth: u32) u64 {
    if (depth == 0) {
        // human presses: path length + A
        const m = movesBetween(dirPos(from), dirPos(to), .{ 0, 0 });
        return m.h + m.v + 1;
    }
    const key = [4]i64{ from, to, @intCast(depth), 0 };
    if (memo.get(key)) |v| return v;

    const m = movesBetween(dirPos(from), dirPos(to), .{ 0, 0 });
    var best: u64 = std.math.maxInt(u64);
    // option 1: H moves then V moves (if valid)
    if (m.ok_hv and m.h > 0) {
        var c: u64 = 0;
        var prev: u8 = from;
        var k: u32 = 0;
        while (k < m.h) : (k += 1) {
            const nxt: u8 = if (m.dir_h > 0) '>' else '<';
            c += dirCost(prev, nxt, depth - 1);
            prev = nxt;
        }
        k = 0;
        while (k < m.v) : (k += 1) {
            const nxt: u8 = if (m.dir_v > 0) 'v' else '^';
            c += dirCost(prev, nxt, depth - 1);
            prev = nxt;
        }
        c += dirCost(prev, 'A', depth - 1);
        best = @min(best, c);
    }
    // option 2: V then H
    if (m.ok_vh and m.v > 0) {
        var c: u64 = 0;
        var prev: u8 = from;
        var k: u32 = 0;
        while (k < m.v) : (k += 1) {
            const nxt: u8 = if (m.dir_v > 0) 'v' else '^';
            c += dirCost(prev, nxt, depth - 1);
            prev = nxt;
        }
        k = 0;
        while (k < m.h) : (k += 1) {
            const nxt: u8 = if (m.dir_h > 0) '>' else '<';
            c += dirCost(prev, nxt, depth - 1);
            prev = nxt;
        }
        c += dirCost(prev, 'A', depth - 1);
        best = @min(best, c);
    }
    if (best == std.math.maxInt(u64)) {
        // pure vertical or pure horizontal path (both options same)
        var c: u64 = 0;
        var prev: u8 = from;
        var k: u32 = 0;
        while (k < m.h) : (k += 1) {
            const nxt: u8 = if (m.dir_h > 0) '>' else '<';
            c += dirCost(prev, nxt, depth - 1);
            prev = nxt;
        }
        k = 0;
        while (k < m.v) : (k += 1) {
            const nxt: u8 = if (m.dir_v > 0) 'v' else '^';
            c += dirCost(prev, nxt, depth - 1);
            prev = nxt;
        }
        c += dirCost(prev, 'A', depth - 1);
        best = c;
    }
    memo.put(key, best) catch {};
    return best;
}

fn codeComplexity(depth: u32) !u64 {
    var total: u64 = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |code| {
        var c: u64 = 0;
        var prev: u8 = 'A';
        for (code) |target| {
            // numeric pad move (one robot, the one right above the numbers)
            const m = movesBetween(numPos(prev), numPos(target), .{ 0, 3 });
            var best: u64 = std.math.maxInt(u64);
            // H then V
            if (m.ok_hv) {
                var cc: u64 = 0;
                var p: u8 = 'A';
                var k: u32 = 0;
                while (k < m.h) : (k += 1) {
                    const nxt: u8 = if (m.dir_h > 0) '>' else '<';
                    cc += dirCost(p, nxt, depth);
                    p = nxt;
                }
                k = 0;
                while (k < m.v) : (k += 1) {
                    const nxt: u8 = if (m.dir_v > 0) 'v' else '^';
                    cc += dirCost(p, nxt, depth);
                    p = nxt;
                }
                cc += dirCost(p, 'A', depth);
                best = @min(best, cc);
            }
            if (m.ok_vh) {
                var cc: u64 = 0;
                var p: u8 = 'A';
                var k: u32 = 0;
                while (k < m.v) : (k += 1) {
                    const nxt: u8 = if (m.dir_v > 0) 'v' else '^';
                    cc += dirCost(p, nxt, depth);
                    p = nxt;
                }
                k = 0;
                while (k < m.h) : (k += 1) {
                    const nxt: u8 = if (m.dir_h > 0) '>' else '<';
                    cc += dirCost(p, nxt, depth);
                    p = nxt;
                }
                cc += dirCost(p, 'A', depth);
                best = @min(best, cc);
            }
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
    print("part 1: {d}\n", .{try codeComplexity(2)});
    print("part 2: {d}\n", .{try codeComplexity(25)});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
