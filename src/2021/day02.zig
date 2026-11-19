const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day02.txt");

pub fn main() !void {
    var h1: i64 = 0;
    var d1: i64 = 0;
    var h2: i64 = 0;
    var d2: i64 = 0;
    var aim: i64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const sp = indexOf(u8, line, ' ').?;
        const n = try parseInt(i64, line[sp + 1 ..], 10);
        switch (line[0]) {
            'f' => {
                h1 += n;
                h2 += n;
                d2 += aim * n;
            },
            'd' => {
                d1 += n;
                aim += n;
            },
            'u' => {
                d1 -= n;
                aim -= n;
            },
            else => {},
        }
    }
    print("part 1: {d}\n", .{h1 * d1});
    print("part 2: {d}\n", .{h2 * d2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
