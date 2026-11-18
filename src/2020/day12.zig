const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day12.txt");

/// Rotate clockwise by `degrees` (multiples of 90): (x, y) -> (y, -x).
fn rotate(way: [2]i64, degrees: i32) [2]i64 {
    var v = way;
    var d = degrees;
    while (d > 0) : (d -= 90) {
        v = .{ v[1], -v[0] };
    }
    return v;
}

pub fn main() !void {
    // part 1: absolute navigation
    {
        var x: i64 = 0;
        var y: i64 = 0;
        var dx: i64 = 1;
        var dy: i64 = 0;
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            const n = try parseInt(i64, line[1..], 10);
            switch (line[0]) {
                'N' => y += n,
                'S' => y -= n,
                'E' => x += n,
                'W' => x -= n,
                'F' => {
                    x += dx * n;
                    y += dy * n;
                },
                'L' => {
                    const t = rotate(.{ dx, dy }, @intCast(360 - n));
                    dx = t[0];
                    dy = t[1];
                },
                'R' => {
                    const t = rotate(.{ dx, dy }, @intCast(n));
                    dx = t[0];
                    dy = t[1];
                },
                else => {},
            }
        }
        print("part 1: {d}\n", .{@abs(x) + @abs(y)});
    }

    // part 2: waypoint navigation
    {
        var sx: i64 = 0;
        var sy: i64 = 0;
        var wx: i64 = 10;
        var wy: i64 = 1;
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            const n = try parseInt(i64, line[1..], 10);
            switch (line[0]) {
                'N' => wy += n,
                'S' => wy -= n,
                'E' => wx += n,
                'W' => wx -= n,
                'F' => {
                    sx += wx * n;
                    sy += wy * n;
                },
                'L' => {
                    const t = rotate(.{ wx, wy }, @intCast(360 - n));
                    wx = t[0];
                    wy = t[1];
                },
                'R' => {
                    const t = rotate(.{ wx, wy }, @intCast(n));
                    wx = t[0];
                    wy = t[1];
                },
                else => {},
            }
        }
        print("part 2: {d}\n", .{@abs(sx) + @abs(sy)});
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
