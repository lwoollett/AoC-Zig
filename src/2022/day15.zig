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

const Sensor = struct { sx: i64, sy: i64, bx: i64, by: i64 };

fn excludedRange(s: Sensor, row: i64) ?[2]i64 {
    const dist = @abs(s.sx - s.bx) + @abs(s.sy - s.by);
    const row_dist = @abs(s.sy - row);
    if (row_dist > dist) return null;
    const span: i64 = @intCast(dist - row_dist);
    return .{ s.sx - span, s.sx + span };
}

pub fn main() !void {
    var sensors: List(Sensor) = .empty;
    defer sensors.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "Sensor at x=S, y=S: closest beacon is at x=B, y=B"
        const c1 = indexOf(u8, line, ',').?; // after SX
        const colon = indexOf(u8, line, ':').?;
        const c2 = indexOf(u8, line[colon..], ',').? + colon; // after BX
        const sx = try parseInt(i64, line[12..c1], 10);
        const sy = try parseInt(i64, line[c1 + 4 .. colon], 10);
        const bx = try parseInt(i64, line[colon + 25 .. c2], 10);
        const by = try parseInt(i64, line[c2 + 4 ..], 10);
        try sensors.append(gpa, .{ .sx = sx, .sy = sy, .bx = bx, .by = by });
    }

    // part 1: row 2000000
    const row: i64 = 2000000;
    {
        var ranges: List([2]i64) = .empty;
        defer ranges.deinit(gpa);
        for (sensors.items) |s| {
            if (excludedRange(s, row)) |r| {
                try ranges.append(gpa, r);
            }
        }
        std.mem.sort([2]i64, ranges.items, {}, struct {
            fn lessThan(_: void, a: [2]i64, b: [2]i64) bool {
                return a[0] < b[0];
            }
        }.lessThan);
        var covered: i64 = 0;
        var cur: [2]i64 = .{ std.math.minInt(i64), std.math.minInt(i64) };
        for (ranges.items) |r| {
            if (r[0] > cur[1]) {
                covered += cur[1] - cur[0] + 1;
                cur = r;
            } else {
                cur[1] = @max(cur[1], r[1]);
            }
        }
        covered += cur[1] - cur[0] + 1;
        // subtract beacons on this row
        var beacons_on_row: i64 = 0;
        var seen = Map([2]i64, void).init(gpa);
        defer seen.deinit();
        for (sensors.items) |s| {
            if (s.by == row and !seen.contains(.{ s.bx, s.by })) {
                try seen.put(.{ s.bx, s.by }, {});
                // only count if inside some excluded range
                for (ranges.items) |r| {
                    if (s.bx >= r[0] and s.bx <= r[1]) {
                        beacons_on_row += 1;
                        break;
                    }
                }
            }
        }
        print("part 1: {d}\n", .{covered - beacons_on_row - 1}); // +1 count offset from the sentinel start
    }

    // part 2: find the gap
    {
        const limit: i64 = 4000000;
        var y: i64 = 0;
        var ranges: List([2]i64) = .empty;
        defer ranges.deinit(gpa);
        while (y <= limit) : (y += 1) {
            ranges.clearRetainingCapacity();
            for (sensors.items) |s| {
                if (excludedRange(s, y)) |r| {
                    try ranges.append(gpa, r);
                }
            }
            std.mem.sort([2]i64, ranges.items, {}, struct {
                fn lessThan(_: void, a: [2]i64, b: [2]i64) bool {
                    return a[0] < b[0];
                }
            }.lessThan);
            var reach: i64 = 0;
            for (ranges.items) |r| {
                if (r[0] > reach + 1 and r[0] > 0 and reach >= 0 and reach <= limit) {
                    const x = reach + 1;
                    print("part 2: {d}\n", .{x * 4000000 + y});
                    return;
                }
                reach = @max(reach, r[1]);
                if (reach > limit) break;
            }
        }
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
