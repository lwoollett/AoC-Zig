const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day17.txt");

const liters = 150;
const max_containers = 24;

pub fn main() !void {
    var sizes: [max_containers]u32 = undefined;
    var n: usize = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        sizes[n] = try parseInt(u32, line, 10);
        n += 1;
    }

    var total_combos: u32 = 0;
    var min_count: usize = maxInt;
    var min_count_combos: u32 = 0;

    var mask: usize = 0;
    while (mask < (@as(usize, 1) << @intCast(n))) : (mask += 1) {
        var sum: u32 = 0;
        var count: usize = 0;
        var bits = mask;
        while (bits != 0) {
            const b = @ctz(bits);
            sum += sizes[b];
            count += 1;
            bits &= bits - 1;
        }
        if (sum == liters) {
            total_combos += 1;
            if (count < min_count) {
                min_count = count;
                min_count_combos = 1;
            } else if (count == min_count) {
                min_count_combos += 1;
            }
        }
    }

    print("part 1: {d}\n", .{total_combos});
    print("part 2: {d}\n", .{min_count_combos});
}

const maxInt = std.math.maxInt(usize);

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
