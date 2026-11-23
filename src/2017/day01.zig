const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day01.txt");

pub fn main() !void {
    const s = trim(u8, data, " \n\r\t");
    const n = s.len;

    var sum1: u32 = 0;
    for (s, 0..) |c, i| {
        if (c == s[(i + 1) % n]) sum1 += c - '0';
    }

    var sum2: u32 = 0;
    const half = n / 2;
    for (s, 0..) |c, i| {
        if (c == s[(i + half) % n]) sum2 += c - '0';
    }

    print("part 1: {d}\n", .{sum1});
    print("part 2: {d}\n", .{sum2});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
