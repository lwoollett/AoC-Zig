const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day23.txt");

const Bot = struct { x: i64, y: i64, z: i64, r: i64 };

fn dist(a: *const Bot, x: i64, y: i64, z: i64) i64 {
    return @as(i64, @intCast(@abs(a.x - x) + @abs(a.y - y) + @abs(a.z - z)));
}

pub fn main() !void {
    var bots: List(Bot) = .empty;
    defer bots.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // pos=<0,0,0>, r=4
        var it = tokenizeAny(u8, line, "pos=<,>r= ");
        const x = try parseInt(i64, it.next().?, 10);
        const y = try parseInt(i64, it.next().?, 10);
        const z = try parseInt(i64, it.next().?, 10);
        const r = try parseInt(i64, it.next().?, 10);
        try bots.append(gpa, .{ .x = x, .y = y, .z = z, .r = r });
    }

    // part 1: bots in range of the strongest
    var strongest: usize = 0;
    for (bots.items, 0..) |b, i| {
        if (b.r > bots.items[strongest].r) strongest = i;
    }
    var in_range: u32 = 0;
    for (bots.items) |b| {
        if (dist(&b, bots.items[strongest].x, bots.items[strongest].y, bots.items[strongest].z) <=
            bots.items[strongest].r)
        {
            in_range += 1;
        }
    }
    print("part 1: {d}\n", .{in_range});

    // part 2: octree search with admissible bounds. For each box, the number
    // of bots whose octahedron can reach ANY point of the box bounds the
    // coverage of every point inside; boxes are popped best-bound-first
    // (ties: smaller best-possible distance to origin), so the first popped
    // single point is exactly the max-coverage, min-distance answer.
    // (Corner enumeration of bot octahedra is a heuristic that can miss the
    // closest point of the winning region entirely.)
    var lo_x: i64 = std.math.maxInt(i64);
    var hi_x: i64 = std.math.minInt(i64);
    var lo_y: i64 = std.math.maxInt(i64);
    var hi_y: i64 = std.math.minInt(i64);
    var lo_z: i64 = std.math.maxInt(i64);
    var hi_z: i64 = std.math.minInt(i64);
    var r_max: i64 = 0;
    for (bots.items) |b| {
        lo_x = @min(lo_x, b.x);
        hi_x = @max(hi_x, b.x);
        lo_y = @min(lo_y, b.y);
        hi_y = @max(hi_y, b.y);
        lo_z = @min(lo_z, b.z);
        hi_z = @max(hi_z, b.z);
        r_max = @max(r_max, b.r);
    }
    lo_x -= r_max;
    lo_y -= r_max;
    lo_z -= r_max;
    hi_x += r_max;
    hi_y += r_max;
    hi_z += r_max;

    const Box = struct {
        lo_x: i64,
        hi_x: i64,
        lo_y: i64,
        hi_y: i64,
        lo_z: i64,
        hi_z: i64,
        bound: u32, // max coverage of any point inside
        dist_bound: i64, // min |x|+|y|+|z| of any point inside
    };

    const Cover = struct {
        fn axisGap(lo: i64, hi: i64, c: i64) i64 {
            if (c < lo) return lo - c;
            if (c > hi) return c - hi;
            return 0;
        }
        fn boxDist(bots_l: []const Bot, bx: Box) struct { count: u32, dist: i64 } {
            var count: u32 = 0;
            for (bots_l) |*b| {
                const d = axisGap(bx.lo_x, bx.hi_x, b.x) +
                    axisGap(bx.lo_y, bx.hi_y, b.y) +
                    axisGap(bx.lo_z, bx.hi_z, b.z);
                if (d <= b.r) count += 1;
            }
            var d_origin: i64 = 0;
            for ([_][2]i64{ .{ bx.lo_x, bx.hi_x }, .{ bx.lo_y, bx.hi_y }, .{ bx.lo_z, bx.hi_z } }) |ax| {
                if (ax[0] > 0) d_origin += ax[0] else if (ax[1] < 0) d_origin += -ax[1];
            }
            return .{ .count = count, .dist = d_origin };
        }
    };

    var pq = std.PriorityQueue(Box, void, struct {
        fn lessThan(_: void, a: Box, b: Box) std.math.Order {
            // pop best bound first; tie -> smaller origin-distance bound
            if (a.bound != b.bound) return std.math.order(b.bound, a.bound);
            return std.math.order(a.dist_bound, b.dist_bound);
        }
    }.lessThan).initContext({});
    defer pq.deinit(gpa);

    const root_stats = Cover.boxDist(bots.items, .{ .lo_x = lo_x, .hi_x = hi_x, .lo_y = lo_y, .hi_y = hi_y, .lo_z = lo_z, .hi_z = hi_z, .bound = 0, .dist_bound = 0 });
    try pq.push(gpa, .{ .lo_x = lo_x, .hi_x = hi_x, .lo_y = lo_y, .hi_y = hi_y, .lo_z = lo_z, .hi_z = hi_z, .bound = root_stats.count, .dist_bound = root_stats.dist });

    while (pq.pop()) |bx| {
        if (bx.lo_x == bx.hi_x and bx.lo_y == bx.hi_y and bx.lo_z == bx.hi_z) {
            const d: i64 = @intCast(@abs(bx.lo_x) + @abs(bx.lo_y) + @abs(bx.lo_z));
            print("part 2: {d}\n", .{d});
            return;
        }
        const mx = @divFloor(bx.lo_x + bx.hi_x, 2);
        const my = @divFloor(bx.lo_y + bx.hi_y, 2);
        const mz = @divFloor(bx.lo_z + bx.hi_z, 2);
        for ([_][2]i64{ .{ bx.lo_x, mx }, .{ mx + 1, bx.hi_x } }) |xr| {
            for ([_][2]i64{ .{ bx.lo_y, my }, .{ my + 1, bx.hi_y } }) |yr| {
                for ([_][2]i64{ .{ bx.lo_z, mz }, .{ mz + 1, bx.hi_z } }) |zr| {
                    const child = Box{ .lo_x = xr[0], .hi_x = xr[1], .lo_y = yr[0], .hi_y = yr[1], .lo_z = zr[0], .hi_z = zr[1], .bound = 0, .dist_bound = 0 };
                    const st = Cover.boxDist(bots.items, child);
                    try pq.push(gpa, .{ .lo_x = child.lo_x, .hi_x = child.hi_x, .lo_y = child.lo_y, .hi_y = child.hi_y, .lo_z = child.lo_z, .hi_z = child.hi_z, .bound = st.count, .dist_bound = st.dist });
                }
            }
        }
    }
    return error.NoAnswer;
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
