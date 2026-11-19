const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// The zom Managed Object Runtime (../zom) is available to every day.
// To use managed objects, uncomment the import below (or reference zom
// anywhere in this file) and rebuild — the day is then compiled and
// linked with zom and its vendored SQLite automatically:
// const zom = @import("zom");

const data = @embedFile("data/day01.txt");

pub fn main() !void {
    // Part 1: final floor after ( = up, ) = down.
    var floor: i32 = 0;
    var basement: i32 = -1;
    for (data, 0..) |c, i| {
        floor += switch (c) {
            '(' => 1,
            ')' => -1,
            else => 0,
        };
        if (basement == -1 and floor == -1) basement = @intCast(i + 1);
    }
    print("part 1: {d}\n", .{floor});
    print("part 2: {d}\n", .{basement});
}

// Useful stdlib functions

const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
