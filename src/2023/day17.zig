const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day17.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat(0));
var h: usize = 0;
var w: usize = 0;

const Item = struct {
    cost: u64,
    x: usize,
    y: usize,
    dx: i8,
    dy: i8,
    run: u8,
};

/// min_run/max_run: crucible straight-block constraints
fn solve(comptime min_run: u8, comptime max_run: u8) !u64 {
    var dist = Map([5]i64, u64).init(gpa);
    defer dist.deinit();
    var pq = std.PriorityQueue(Item, void, struct {
        fn lessThan(_: void, a: Item, b: Item) std.math.Order {
            return std.math.order(a.cost, b.cost);
        }
    }.lessThan).initContext({});
    defer pq.deinit(gpa);

    // start: two directions (east/south), run 1 at cost of first cell
    try dist.put(.{ 0, 0, 1, 0, 0 }, 0);
    try pq.push(gpa, .{ .cost = 0, .x = 0, .y = 0, .dx = 1, .dy = 0, .run = 0 });

    while (pq.pop()) |cur| {
        if (cur.x == w - 1 and cur.y == h - 1 and cur.run >= min_run) {
            return cur.cost;
        }
        const key = [5]i64{ @intCast(cur.x), @intCast(cur.y), cur.dx, cur.dy, cur.run };
        if ((dist.get(key) orelse std.math.maxInt(u64)) < cur.cost) continue;

        // moves: straight (if run < max_run) or turn left/right (if run >= min_run)
        const dirs = [4][2]i8{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } };
        for (dirs) |d| {
            // no reversing
            if (d[0] == -cur.dx and d[1] == -cur.dy) continue;
            const straight = (d[0] == cur.dx and d[1] == cur.dy);
            var nrun: u8 = undefined;
            if (straight) {
                if (cur.run >= max_run) continue;
                nrun = cur.run + 1;
            } else {
                if (cur.run < min_run) continue;
                nrun = 1;
            }
            const nx = @as(i64, @intCast(cur.x)) + d[0];
            const ny = @as(i64, @intCast(cur.y)) + d[1];
            if (nx < 0 or ny < 0 or nx >= w or ny >= h) continue;
            const ncost = cur.cost + grid[@intCast(ny)][@intCast(nx)] - '0';
            const nkey = [5]i64{ nx, ny, d[0], d[1], nrun };
            if (ncost < dist.get(nkey) orelse std.math.maxInt(u64)) {
                try dist.put(nkey, ncost);
                try pq.push(gpa, .{ .cost = ncost, .x = @intCast(nx), .y = @intCast(ny), .dx = d[0], .dy = d[1], .run = nrun });
            }
        }
    }
    return error.NoPath;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }
    print("part 1: {d}\n", .{try solve(1, 3)});
    print("part 2: {d}\n", .{try solve(4, 10)});
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
// Only unmodified days will be modified.
