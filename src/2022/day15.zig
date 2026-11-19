const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day15.txt");

const Sensor = struct { sx: i64, sy: i64, bx: i64, by: i64 };

/// Intersection of border lines x+y=c1 and x-y=c2: the candidate gap point,
/// returned if it is in bounds and uncovered by every sensor.
fn tryCandidate(sensors: []const Sensor, c1: i64, c2: i64, limit: i64) ?[2]i64 {
    if (@mod(c1 + c2, 2) != 0) return null; // need an integral x
    const x = @divTrunc(c1 + c2, 2);
    const y = c1 - x;
    if (x < 0 or y < 0 or x > limit or y > limit) return null;
    for (sensors) |s| {
        if (@abs(s.sx - x) + @abs(s.sy - y) <= @abs(s.sx - s.bx) + @abs(s.sy - s.by)) return null;
    }
    return .{ x, y };
}

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

    // part 2: find the gap. With a unique uncovered point, it must sit on
    // the d+1 border diamond of (at least) two sensors — specifically at the
    // intersection of a slope -1 edge (x+y = c1) of one sensor with a slope +1
    // edge (x-y = c2) of another. Check all such candidates, fall back to a
    // row scan if none verifies (shouldn't happen with unique answers).
    {
        const limit: i64 = 4000000;
        var found: ?[2]i64 = null;
        outer: for (sensors.items, 0..) |si, i| {
            const di: i64 = @intCast(@abs(si.sx - si.bx) + @abs(si.sy - si.by) + 1);
            for (sensors.items[i + 1 ..]) |sj| {
                const dj: i64 = @intCast(@abs(sj.sx - sj.bx) + @abs(sj.sy - sj.by) + 1);
                // a slope -1 edge (x+y=c1) of one sensor crossing a slope +1
                // edge (x-y=c2) of the other — both orientations per pair
                for ([2]i64{ si.sx + si.sy + di, si.sx + si.sy - di }) |c1| {
                    for ([2]i64{ sj.sx - sj.sy + dj, sj.sx - sj.sy - dj }) |c2| {
                        if (tryCandidate(sensors.items, c1, c2, limit)) |p| {
                            found = p;
                            break :outer;
                        }
                    }
                }
                for ([2]i64{ sj.sx + sj.sy + dj, sj.sx + sj.sy - dj }) |c1| {
                    for ([2]i64{ si.sx - si.sy + di, si.sx - si.sy - di }) |c2| {
                        if (tryCandidate(sensors.items, c1, c2, limit)) |p| {
                            found = p;
                            break :outer;
                        }
                    }
                }
            }
        }
        if (found) |p| {
            print("part 2: {d}\n", .{p[0] * 4000000 + p[1]});
        } else {
            // fallback: exhaustive row scan
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
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
