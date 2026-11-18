const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day10.txt");

const gw = 100;
const gh = 100;
var grid: [gh][gw]u8 = @splat(@splat(0));
var h: usize = 0;
var w: usize = 0;

/// BFS from a trailhead: score = distinct 9s reached; rating = distinct paths.
fn explore(sx: usize, sy: usize) ![2]u64 {
    var reached = Map([2]usize, void).init(gpa);
    defer reached.deinit();
    var paths = Map([2]usize, u64).init(gpa);
    defer paths.deinit();
    var q: List([2]usize) = .empty;
    defer q.deinit(gpa);
    try paths.put(.{ sx, sy }, 1);
    try q.append(gpa, .{ sx, sy });
    var head: usize = 0;
    while (head < q.items.len) : (head += 1) {
        const cur = q.items[head];
        const v = grid[cur[1]][cur[0]];
        if (v == '9') {
            try reached.put(cur, {});
            continue;
        }
        const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
        for (deltas) |d| {
            const nx = @as(i32, @intCast(cur[0])) + d[0];
            const ny = @as(i32, @intCast(cur[1])) + d[1];
            if (nx < 0 or ny < 0 or nx >= w or ny >= h) continue;
            if (grid[@intCast(ny)][@intCast(nx)] != v + 1) continue;
            const key = [2]usize{ @intCast(nx), @intCast(ny) };
            const gop = try paths.getOrPut(key);
            if (!gop.found_existing) {
                gop.value_ptr.* = 0;
                try q.append(gpa, key);
            }
            gop.value_ptr.* += paths.get(cur).?;
        }
    }
    var rating: u64 = 0;
    var it = reached.keyIterator();
    while (it.next()) |k| {
        rating += paths.get(k.*).?;
    }
    return .{ reached.count(), rating };
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    var total_score: u64 = 0;
    var total_rating: u64 = 0;
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == '0') {
                const r = try explore(x, y);
                total_score += r[0];
                total_rating += r[1];
            }
        }
    }
    print("part 1: {d}\n", .{total_score});
    print("part 2: {d}\n", .{total_rating});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.findScalar;
const indexOfAny = std.mem.findAny;
const indexOfStr = std.mem.findPos;
const lastIndexOf = std.mem.findScalarLast;
const lastIndexOfAny = std.mem.findLastAny;
const lastIndexOfStr = std.mem.findLastLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
