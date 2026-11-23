const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day21.txt");

const gw = 400;
const gh = 400;
var grid: [gh][gw]u8 = @splat(@splat('#'));
var h: usize = 0;
var w: usize = 0;
var sx: usize = 0;
var sy: usize = 0;

/// reachable cell count after exactly `steps` BFS from S (grid repeats infinitely)
fn reachable(steps: u64) !u64 {
    // BFS on the infinite grid, capped at distance = steps
    var visited = Map([2]i64, void).init(gpa);
    defer visited.deinit();
    var frontier: List([2]i64) = .empty;
    defer frontier.deinit(gpa);
    try visited.put(.{ @intCast(sx), @intCast(sy) }, {});
    try frontier.append(gpa, .{ @intCast(sx), @intCast(sy) });

    // "reachable in exactly `steps`" = every cell whose shortest distance
    // is <= steps with matching parity (wandering back and forth is allowed),
    // not just the distance-==steps ring
    const want_parity: u64 = steps % 2;
    var total: u64 = if (want_parity == 0) 1 else 0; // the start cell
    var d: u64 = 0;
    while (d < steps) : (d += 1) {
        var next: List([2]i64) = .empty;
        defer next.deinit(gpa);
        for (frontier.items) |p| {
            const deltas = [4][2]i64{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
            for (deltas) |dl| {
                const nx = p[0] + dl[0];
                const ny = p[1] + dl[1];
                // mod into the base grid
                const gx = @mod(nx, @as(i64, @intCast(w)));
                const gy = @mod(ny, @as(i64, @intCast(h)));
                if (grid[@intCast(gy)][@intCast(gx)] == '#') continue;
                const key = [2]i64{ nx, ny };
                if (visited.contains(key)) continue;
                try visited.put(key, {});
                try next.append(gpa, key);
            }
        }
        frontier.clearRetainingCapacity();
        try frontier.appendSlice(gpa, next.items);
        if ((d + 1) % 2 == want_parity) total += frontier.items.len;
    }
    return total;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        for (line, 0..) |c, x| {
            if (c == 'S') {
                sx = x;
                sy = h;
            }
        }
        w = @max(w, line.len);
        h += 1;
    }

    print("part 1: {d}\n", .{try reachable(64)});

    // part 2: quadratic fit using 3 sample points: steps = w/2 + k*w
    // (assumes the standard odd-grid diamond layout)
    const half = w / 2;
    const f0 = try reachable(half);
    const f1 = try reachable(half + w);
    const f2 = try reachable(half + 2 * w);

    const target: u128 = 26501365;
    const k: u128 = (target - half) / w;
    // fit ax^2 + bx + c through (0,f0), (1,f1), (2,f2)
    const a: i128 = @intCast(@divTrunc(@as(i64, @intCast(f2)) - 2 * @as(i64, @intCast(f1)) + @as(i64, @intCast(f0)), 2));
    const b: i128 = @intCast(@as(i64, @intCast(f1)) - @as(i64, @intCast(f0)) - a);
    const c: i128 = @intCast(f0);
    const kk: i128 = @intCast(k);
    const result: i128 = a * kk * kk + b * kk + c;
    print("part 2: {d}\n", .{result});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
