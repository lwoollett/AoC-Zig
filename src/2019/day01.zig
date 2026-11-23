const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day01.txt");

fn fuel(mass: i64) i64 {
    return @divTrunc(mass, 3) - 2;
}

pub fn main() !void {
    var total: i64 = 0;
    var total_recursive: i64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const mass = try parseInt(i64, line, 10);
        const f = fuel(mass);
        total += f;
        // p2: keep fueling the fuel
        var extra = fuel(f);
        while (extra > 0) {
            total_recursive += extra;
            extra = fuel(extra);
        }
        total_recursive += f;
    }

    print("part 1: {d}\n", .{total});
    print("part 2: {d}\n", .{total_recursive});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
