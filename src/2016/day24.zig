const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day24.txt");

const max_pois = 8;

const gw = 256;
const gh = 64;
var grid: [gh][gw]u8 = @splat(@splat('#'));
var w: usize = 0;
var h: usize = 0;
var poi_pos: [max_pois][2]usize = @splat(.{ 0, 0 });
var n_pois: usize = 0;

/// BFS distance between two cells, avoiding walls.
fn bfsDist(from: [2]usize, to: [2]usize) !u32 {
    var dist: [gh][gw]i32 = @splat(@splat(-1));
    var queue: List([2]usize) = .empty;
    defer queue.deinit(gpa);
    try queue.append(gpa, from);
    dist[from[1]][from[0]] = 0;
    var qi: usize = 0;
    while (qi < queue.items.len) : (qi += 1) {
        const cur = queue.items[qi];
        if (cur[0] == to[0] and cur[1] == to[1]) return @intCast(dist[cur[1]][cur[0]]);
        const d = dist[cur[1]][cur[0]];
        const moves = [4][2]i32{ .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 }, .{ 0, -1 } };
        for (moves) |m| {
            const nx = @as(i64, @intCast(cur[0])) + m[0];
            const ny = @as(i64, @intCast(cur[1])) + m[1];
            if (nx < 0 or ny < 0) continue;
            const ux: usize = @intCast(nx);
            const uy: usize = @intCast(ny);
            if (ux >= w or uy >= h) continue;
            if (grid[uy][ux] == '#') continue;
            if (dist[uy][ux] != -1) continue;
            dist[uy][ux] = d + 1;
            try queue.append(gpa, .{ ux, uy });
        }
    }
    return error.Unreachable;
}

var best1: u64 = std.math.maxInt(u64);
var best2: u64 = std.math.maxInt(u64);

fn permute(order: *[max_pois]usize, used: *[max_pois]bool, depth: usize, dist: *const [max_pois][max_pois]u32) void {
    if (depth == n_pois) {
        var t: u64 = 0;
        var prev: usize = 0;
        for (order[0..n_pois]) |p| {
            t += dist[prev][p];
            prev = p;
        }
        best1 = @min(best1, t);
        best2 = @min(best2, t + dist[prev][0]);
        return;
    }
    var c: usize = 1; // POI 0 (start) stays first
    while (c < n_pois) : (c += 1) {
        if (used[c]) continue;
        used[c] = true;
        order[depth] = c;
        permute(order, used, depth + 1, dist);
        used[c] = false;
    }
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n\r");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        w = @max(w, line.len);
        for (line, 0..) |c, x| {
            grid[h][x] = c;
            if (c >= '0' and c <= '9') {
                const idx: usize = c - '0';
                n_pois = @max(n_pois, idx + 1);
                poi_pos[idx] = .{ x, h };
            }
        }
        h += 1;
    }

    // all-pairs distances
    var dist: [max_pois][max_pois]u32 = @splat(@splat(0));
    for (0..n_pois) |i| {
        for (0..n_pois) |j| {
            if (i != j) dist[i][j] = try bfsDist(poi_pos[i], poi_pos[j]);
        }
    }

    var order: [max_pois]usize = @splat(0);
    var used: [max_pois]bool = @splat(false);
    permute(&order, &used, 1, &dist);

    print("part 1: {d}\n", .{best1});
    print("part 2: {d}\n", .{best2});
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
