const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day20.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat('#'));
var h: usize = 0;
var w: usize = 0;

const P = [2]usize;

fn bfsFrom(start: P) !Map(P, i32) {
    // NOTE: caller owns the returned map.
    var dist = Map(P, i32).init(gpa);
    var q: List(P) = .empty;
    defer q.deinit(gpa);
    try dist.put(start, 0);
    try q.append(gpa, start);
    var head: usize = 0;
    while (head < q.items.len) : (head += 1) {
        const cur = q.items[head];
        const d = dist.get(cur).?;
        const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
        for (deltas) |dl| {
            const nx = @as(i32, @intCast(cur[0])) + dl[0];
            const ny = @as(i32, @intCast(cur[1])) + dl[1];
            if (nx < 0 or ny < 0 or nx >= w or ny >= h) continue;
            if (grid[@intCast(ny)][@intCast(nx)] == '#') continue;
            const np: P = .{ @intCast(nx), @intCast(ny) };
            if (dist.contains(np)) continue;
            try dist.put(np, d + 1);
            try q.append(gpa, np);
        }
    }
    return dist;
}

fn countCheats(max_len: i32, min_saving: i32) !u64 {
    // BFS from start and end; for each pair of track cells within manhattan
    // max_len, a cheat saves (dist_s[a] + dist_e[b] + len - normal)
    var start: P = .{ 0, 0 };
    var end: P = .{ 0, 0 };
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == 'S') start = .{ x, y };
            if (grid[y][x] == 'E') end = .{ x, y };
        }
    }
    var ds = try bfsFrom(start);
    var de = try bfsFrom(end);
    defer de.deinit();
    const normal = ds.get(end).?;

    // collect track cells with both distances
    var cells: List(P) = .empty;
    defer cells.deinit(gpa);
    var dit = ds.keyIterator();
    while (dit.next()) |p| {
        if (de.contains(p.*)) {
            try cells.append(gpa, p.*);
        }
    }

    var count: u64 = 0;
    for (cells.items) |a| {
        for (cells.items) |b| {
            if (a[0] == b[0] and a[1] == b[1]) continue;
            const md = @as(i32, @intCast(@abs(@as(i64, @intCast(a[0])) - @as(i64, @intCast(b[0]))))) +
                @as(i32, @intCast(@abs(@as(i64, @intCast(a[1])) - @as(i64, @intCast(b[1])))));
            if (md > max_len) continue;
            const save = ds.get(a).? + de.get(b).? + md - normal;
            if (save >= min_saving) count += 1;
        }
    }
    return count;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }
    print("part 1: {d}\n", .{try countCheats(2, 100)});
    print("part 2: {d}\n", .{try countCheats(20, 100)});
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
