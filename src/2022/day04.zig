const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day04.txt");

pub fn main() !void {
    var count1: u32 = 0;
    var count2: u32 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "a-b,c-d"
        const comma = indexOf(u8, line, ',').?;
        const d1 = indexOf(u8, line[0..comma], '-').?;
        const d2 = lastIndexOf(u8, line, '-').?;
        const a1 = try parseInt(u32, line[0..d1], 10);
        const a2 = try parseInt(u32, line[d1 + 1 .. comma], 10);
        const b1 = try parseInt(u32, line[comma + 1 .. d2], 10);
        const b2 = try parseInt(u32, line[d2 + 1 ..], 10);

        if ((a1 >= b1 and a2 <= b2) or (b1 >= a1 and b2 <= a2)) count1 += 1;
        if (a1 <= b2 and b1 <= a2) count2 += 1;
    }
    print("part 1: {d}\n", .{count1});
    print("part 2: {d}\n", .{count2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const lastIndexOf = std.mem.findScalarLast;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
