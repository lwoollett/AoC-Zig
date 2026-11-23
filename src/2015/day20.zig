const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day20.txt");

const limit = 2_000_000;

pub fn main() !void {
    const target = try parseInt(u64, trim(u8, data, " \n\r\t"), 10);

    // Part 1: each elf visits every multiple of its number.
    {
        const presents = try gpa.alloc(u64, limit + 1);
        defer gpa.free(presents);
        @memset(presents, 0);

        var elf: usize = 1;
        while (elf <= limit) : (elf += 1) {
            var house = elf;
            while (house <= limit) : (house += elf) {
                presents[house] += 10 * @as(u64, elf);
            }
        }
        var house: usize = 1;
        while (house <= limit) : (house += 1) {
            if (presents[house] >= target) break;
        }
        print("part 1: {d}\n", .{house});
    }

    // Part 2: each elf stops after 50 houses, 11 presents per elf.
    {
        const presents = try gpa.alloc(u64, limit + 1);
        defer gpa.free(presents);
        @memset(presents, 0);

        var elf: usize = 1;
        while (elf <= limit) : (elf += 1) {
            var visit: usize = 0;
            while (visit < 50) : (visit += 1) {
                const house = elf * (visit + 1);
                if (house > limit) break;
                presents[house] += 11 * @as(u64, elf);
            }
        }
        var house: usize = 1;
        while (house <= limit) : (house += 1) {
            if (presents[house] >= target) break;
        }
        print("part 2: {d}\n", .{house});
    }
}

// Useful stdlib functions
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
