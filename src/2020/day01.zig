const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day01.txt");

pub fn main() !void {
    var nums: List(u32) = .empty;
    defer nums.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        try nums.append(gpa, try parseInt(u32, line, 10));
    }

    // part 1: pair summing to 2020
    for (nums.items, 0..) |a, i| {
        for (nums.items[i + 1 ..]) |b| {
            if (a + b == 2020) {
                print("part 1: {d}\n", .{a * b});
            }
        }
    }

    // part 2: triple summing to 2020
    outer: for (nums.items, 0..) |a, i| {
        for (nums.items[i + 1 ..], 0..) |b, j| {
            if (a + b >= 2020) continue;
            const c = 2020 - a - b;
            for (nums.items[i + j + 2 ..]) |d| {
                if (d == c) {
                    print("part 2: {d}\n", .{a * b * c});
                    break :outer;
                }
            }
        }
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
