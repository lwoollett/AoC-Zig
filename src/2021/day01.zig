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

    var inc: u32 = 0;
    for (nums.items[1..], 0..) |v, i| {
        if (v > nums.items[i]) inc += 1;
    }
    print("part 1: {d}\n", .{inc});

    var inc3: u32 = 0;
    var i: usize = 3;
    while (i < nums.items.len) : (i += 1) {
        const a = nums.items[i - 3] + nums.items[i - 2] + nums.items[i - 1];
        const b = nums.items[i - 2] + nums.items[i - 1] + nums.items[i];
        if (b > a) inc3 += 1;
    }
    print("part 2: {d}\n", .{inc3});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
