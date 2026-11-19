const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day06.txt");

pub fn main() !void {
    // counts[timer] = number of fish
    var counts: [9]u64 = @splat(0);
    var it = tokenizeSca(u8, trim(u8, data, " \n\r\t"), ',');
    while (it.next()) |tok| {
        const t = try parseInt(usize, tok, 10);
        counts[t] += 1;
    }

    var day: usize = 0;
    while (day < 256) : (day += 1) {
        const parents = counts[0];
        for (0..8) |i| {
            counts[i] = counts[i + 1];
        }
        counts[6] += parents;
        counts[8] = parents;
        if (day == 79) {
            var total: u64 = 0;
            for (counts) |c| total += c;
            print("part 1: {d}\n", .{total});
        }
    }
    var total: u64 = 0;
    for (counts) |c| total += c;
    print("part 2: {d}\n", .{total});
}

// Useful stdlib functions
const tokenizeSca = std.mem.tokenizeScalar;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
