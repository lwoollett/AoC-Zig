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

const total_time = 2503;

const Deer = struct {
    speed: u32,
    fly: u32,
    rest: u32,
};

fn distanceAt(d: Deer, t: usize) u64 {
    const cycle = d.fly + d.rest;
    const full_cycles = t / cycle;
    const rem = t % cycle;
    const flying = @min(rem, d.fly);
    return @as(u64, full_cycles) * d.fly * d.speed + @as(u64, flying) * d.speed;
}

pub fn main() !void {
    var deers: List(Deer) = .empty;
    defer deers.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "Comet can fly 14 km/s for 10 seconds, but then must rest for 127 seconds."
        var it = tokenizeAny(u8, line, " ");
        _ = it.next().?; // name
        _ = it.next().?; // can
        _ = it.next().?; // fly
        const speed = try parseInt(u32, it.next().?, 10);
        _ = it.next().?; // km/s
        _ = it.next().?; // for
        const fly = try parseInt(u32, it.next().?, 10);
        _ = it.next().?; // seconds,
        _ = it.next().?; // but
        _ = it.next().?; // then
        _ = it.next().?; // must
        _ = it.next().?; // rest
        _ = it.next().?; // for
        const rest = try parseInt(u32, trim(u8, it.next().?, "."), 10);

        try deers.append(gpa, .{ .speed = speed, .fly = fly, .rest = rest });
    }

    // Part 1: distance at total_time.
    var max_dist: u64 = 0;
    for (deers.items) |d| {
        max_dist = @max(max_dist, distanceAt(d, total_time));
    }
    print("part 1: {d}\n", .{max_dist});

    // Part 2: points per simulated second.
    var points = try gpa.alloc(u32, deers.items.len);
    defer gpa.free(points);
    @memset(points, 0);

    var t: usize = 1;
    while (t <= total_time) : (t += 1) {
        var lead: u64 = 0;
        for (deers.items) |d| {
            lead = @max(lead, distanceAt(d, t));
        }
        for (deers.items, 0..) |d, i| {
            if (distanceAt(d, t) == lead) points[i] += 1;
        }
    }
    var best_points: u32 = 0;
    for (points) |p| best_points = @max(best_points, p);
    print("part 2: {d}\n", .{best_points});
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
