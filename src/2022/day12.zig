const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day12.txt");

var grid: [64][128]u8 = @splat(@splat(0));
var h: usize = 0;
var w: usize = 0;

const P = [2]usize;

fn height(c: u8) u8 {
    return switch (c) {
        'S' => 'a',
        'E' => 'z',
        else => c,
    };
}

/// BFS from E down to all reachable-by-reverse-climb cells; returns dist map.
fn bfsFromE() !Map(P, u32) {
    var start: P = .{ 0, 0 };
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == 'E') start = .{ x, y };
        }
    }
    var dist = Map(P, u32).init(gpa);
    var q: List(P) = .empty;
    defer q.deinit(gpa);
    try dist.put(start, 0);
    try q.append(gpa, start);
    var head: usize = 0;
    while (head < q.items.len) : (head += 1) {
        const cur = q.items[head];
        const d = dist.get(cur).?;
        const here = height(grid[cur[1]][cur[0]]);
        const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
        for (deltas) |dl| {
            const nx = @as(i32, @intCast(cur[0])) + dl[0];
            const ny = @as(i32, @intCast(cur[1])) + dl[1];
            if (nx < 0 or ny < 0 or nx >= w or ny >= h) continue;
            const np: P = .{ @intCast(nx), @intCast(ny) };
            if (dist.contains(np)) continue;
            // reverse climb: neighbor must be at most 1 HIGHER than here
            const nb = height(grid[np[1]][np[0]]);
            if (nb > here + 1) continue;
            try dist.put(np, d + 1);
            try q.append(gpa, np);
        }
    }
    return dist;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    var dist = try bfsFromE();
    defer dist.deinit();

    // part 1: dist to S
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == 'S') {
                print("part 1: {d}\n", .{dist.get(.{ x, y }).?});
            }
        }
    }

    // part 2: min dist to any 'a' cell
    var best: u32 = std.math.maxInt(u32);
    for (0..h) |y| {
        for (0..w) |x| {
            if (height(grid[y][x]) == 'a') {
                if (dist.get(.{ x, y })) |d| {
                    best = @min(best, d);
                }
            }
        }
    }
    print("part 2: {d}\n", .{best});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
