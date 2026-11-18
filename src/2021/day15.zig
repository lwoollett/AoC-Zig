const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day15.txt");

const scale = 5;

fn riskAt(base: []const []const u8, tile_w: usize, tile_h: usize, x: usize, y: usize) u32 {
    const bx = x % tile_w;
    const by = y % tile_h;
    const add = (x / tile_w) + (y / tile_h);
    var r = base[by][bx] - '0' + @as(u32, @intCast(add));
    r = (r - 1) % 9 + 1;
    return r;
}

fn solve(base: []const []const u8, mult: usize) !u64 {
    const tile_w = base[0].len;
    const tile_h = base.len;
    const w = tile_w * mult;
    const h = tile_h * mult;

    var dist = try gpa.alloc([]u32, h);
    defer {
        for (dist) |d| gpa.free(d);
        gpa.free(dist);
    }
    for (dist) |*d| {
        d.* = try gpa.alloc(u32, w);
        @memset(d.*, std.math.maxInt(u32));
    }

    const Item = struct { d: u32, x: usize, y: usize };
    var pq = std.PriorityQueue(Item, void, struct {
        fn lessThan(_: void, a: Item, b: Item) std.math.Order {
            return std.math.order(a.d, b.d);
        }
    }.lessThan).initContext({});
    defer pq.deinit(gpa);

    dist[0][0] = 0;
    try pq.push(gpa, .{ .d = 0, .x = 0, .y = 0 });
    const goal_x = w - 1;
    const goal_y = h - 1;

    while (pq.pop()) |cur| {
        if (cur.x == goal_x and cur.y == goal_y) {
            return cur.d;
        }
        if (cur.d > dist[cur.y][cur.x]) continue;
        const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
        for (deltas) |dl| {
            const nx = @as(i64, @intCast(cur.x)) + dl[0];
            const ny = @as(i64, @intCast(cur.y)) + dl[1];
            if (nx < 0 or ny < 0 or nx >= w or ny >= h) continue;
            const xx: usize = @intCast(nx);
            const yy: usize = @intCast(ny);
            const nd = cur.d + riskAt(base, tile_w, tile_h, xx, yy);
            if (nd < dist[yy][xx]) {
                dist[yy][xx] = nd;
                try pq.push(gpa, .{ .d = nd, .x = xx, .y = yy });
            }
        }
    }
    return error.NoPath;
}

pub fn main() !void {
    var base: List([]const u8) = .empty;
    defer base.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        try base.append(gpa, line);
    }
    print("part 1: {d}\n", .{try solve(base.items, 1)});
    print("part 2: {d}\n", .{try solve(base.items, 5)});
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
