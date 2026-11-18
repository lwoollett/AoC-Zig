const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day14.txt");

const Robot = struct { px: i64, py: i64, vx: i64, vy: i64 };

const w = 101;
const h = 103;

pub fn main() !void {
    var robots: List(Robot) = .empty;
    defer robots.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, "p=,v ");
        const px = try parseInt(i64, it.next().?, 10);
        const py = try parseInt(i64, it.next().?, 10);
        const vx = try parseInt(i64, it.next().?, 10);
        const vy = try parseInt(i64, it.next().?, 10);
        try robots.append(gpa, .{ .px = px, .py = py, .vx = vx, .vy = vy });
    }

    // part 1: after 100 seconds
    {
        var q = [4]u64{ 0, 0, 0, 0 };
        for (robots.items) |r| {
            const x = @mod(r.px + r.vx * 100, w);
            const y = @mod(r.py + r.vy * 100, h);
            if (x == w / 2 or y == h / 2) continue;
            const qx: usize = if (x < w / 2) 0 else 1;
            const qy: usize = if (y < h / 2) 0 else 1;
            q[qy * 2 + qx] += 1;
        }
        print("part 1: {d}\n", .{q[0] * q[1] * q[2] * q[3]});
    }

    // part 2: find the frame where robots form the christmas tree —
    // heuristic: minimal quadrant-entropy / most clustered frame
    {
        var best_t: u64 = 0;
        var best_score: i64 = std.math.minInt(i64);
        var t: u64 = 0;
        while (t < 10000) : (t += 1) {
            // count robots sharing a cell with another (clusters)
            var seen = Map([2]i64, u32).init(gpa);
            defer seen.deinit();
            for (robots.items) |r| {
                const x = @mod(r.px + r.vx * @as(i64, @intCast(t)), w);
                const y = @mod(r.py + r.vy * @as(i64, @intCast(t)), h);
                const gop = try seen.getOrPut(.{ x, y });
                if (!gop.found_existing) gop.value_ptr.* = 0;
                gop.value_ptr.* += 1;
            }
            var clustered: i64 = 0;
            var sit = seen.valueIterator();
            while (sit.next()) |c| {
                if (c.* > 1) clustered += c.* - 1;
            }
            if (clustered > best_score) {
                best_score = clustered;
                best_t = t;
            }
        }
        print("part 2: {d}\n", .{best_t});
    }
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
