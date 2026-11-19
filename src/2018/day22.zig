const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day22.txt");

const depth = 3198;
const tx = 12;
const ty = 757;

const size = 800; // must cover the target (12, 757)
// tools: 0 = neither, 1 = torch, 2 = climbing
// rocky(0): torch, climbing; wet(1): climbing, neither; narrow(2): neither, torch

fn geoIndex(x: usize, y: usize) u64 {
    if (x == 0 and y == 0) return 0;
    if (x == tx and y == ty) return 0;
    if (y == 0) return @as(u64, x) * 16807;
    if (x == 0) return @as(u64, y) * 48271;
    return erosion(x - 1, y) * erosion(x, y - 1);
}

var erosion_cache: [size][size]u64 = @splat(@splat(0));
var cached: [size][size]bool = @splat(@splat(false));

fn erosion(x: usize, y: usize) u64 {
    if (x >= size or y >= size) return 0;
    if (cached[y][x]) return erosion_cache[y][x];
    const e = (geoIndex(x, y) + depth) % 20183;
    erosion_cache[y][x] = e;
    cached[y][x] = true;
    return e;
}

fn region(x: usize, y: usize) u2 {
    return @intCast(erosion(x, y) % 3);
}

fn toolAllowed(tool: u2, x: usize, y: usize) bool {
    return switch (regions[y][x]) {
        0 => tool == 1 or tool == 2, // rocky: torch or climbing
        1 => tool == 2 or tool == 0, // wet: climbing or neither
        else => tool == 0 or tool == 1, // narrow: neither or torch
    };
}

const State = struct { x: u16, y: u16, tool: u2, cost: u32 };
var regions: [size][size]u8 = @splat(@splat(255)); // 0..2, 255 = uncached

pub fn main() !void {
    // part 1: risk of the rectangle up to the target
    var risk: u64 = 0;
    for (0..ty + 1) |y| {
        for (0..tx + 1) |x| {
            risk += region(x, y);
        }
    }
    print("part 1: {d}\n", .{risk});

    // precompute the region grid once (erosion recursion amortizes here,
    // not per-check inside the Dijkstra hot loop)
    for (0..size) |yy| {
        for (0..size) |xx| {
            regions[yy][xx] = @intCast(region(xx, yy));
        }
    }

    // part 2: Dijkstra over (x, y, tool) with a binary heap
    var dist = try gpa.alloc([3]u32, size * size);
    defer gpa.free(dist);
    @memset(dist, [3]u32{ std.math.maxInt(u32), std.math.maxInt(u32), std.math.maxInt(u32) });
    dist[0][1] = 0; // (0,0) with torch

    var heap = std.PriorityQueue(State, void, struct {
        fn lessThan(_: void, a: State, b: State) std.math.Order {
            return std.math.order(a.cost, b.cost);
        }
    }.lessThan).initContext({});
    defer heap.deinit(gpa);
    try heap.push(gpa, .{ .x = 0, .y = 0, .tool = 1, .cost = 0 });

    while (heap.pop()) |cur| {
        const cidx = @as(usize, cur.y) * size + cur.x;
        if (cur.cost > dist[cidx][cur.tool]) continue;

        if (cur.x == tx and cur.y == ty and cur.tool == 1) {
            print("part 2: {d}\n", .{cur.cost});
            return;
        }

        for (0..3) |t| {
            const tt: u2 = @intCast(t);
            if (tt == cur.tool) continue;
            if (!toolAllowed(tt, cur.x, cur.y)) continue;
            if (cur.cost + 7 < dist[cidx][t]) {
                dist[cidx][t] = cur.cost + 7;
                try heap.push(gpa, .{ .x = cur.x, .y = cur.y, .tool = tt, .cost = cur.cost + 7 });
            }
        }
        const moves = [4][2]i32{ .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 }, .{ 0, -1 } };
        for (moves) |m| {
            const nx = @as(i64, @intCast(cur.x)) + m[0];
            const ny = @as(i64, @intCast(cur.y)) + m[1];
            if (nx < 0 or ny < 0) continue;
            const ux: usize = @intCast(nx);
            const uy: usize = @intCast(ny);
            if (ux >= size or uy >= size) continue;
            if (!toolAllowed(cur.tool, ux, uy)) continue;
            const idx = uy * size + ux;
            if (cur.cost + 1 < dist[idx][cur.tool]) {
                dist[idx][cur.tool] = cur.cost + 1;
                try heap.push(gpa, .{ .x = @intCast(ux), .y = @intCast(uy), .tool = cur.tool, .cost = cur.cost + 1 });
            }
        }
    }
}

// Useful stdlib functions

const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
