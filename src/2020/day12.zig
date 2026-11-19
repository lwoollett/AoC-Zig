const std = @import("std");

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
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
