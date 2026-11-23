const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

const data = @embedFile("data/day01.txt");

pub fn main() !void {
    var pos: i64 = 50;
    var count1: u64 = 0;
    var count2: u64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const n = try parseInt(i64, line[1..], 10);
        // during a rotation of |n| clicks, the dial passes 0 floor(|n|/100) times
        count2 += @intCast(@divTrunc(if (n < 0) -n else n, 100));

        pos = if (line[0] == 'L') pos - n else pos + n;
        pos = @mod(pos, 100);
        if (pos == 0) {
            count1 += 1;
            count2 += 1;
        }
    }
    print("part 1: {d}\n", .{count1});
    print("part 2: {d}\n", .{count2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
