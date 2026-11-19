const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day06.txt");

fn marker(line: []const u8, size: usize) usize {
    for (size..line.len + 1) |i| {
        const window = line[i - size .. i];
        var all_distinct = true;
        for (window, 0..) |a, x| {
            for (window[x + 1 ..]) |b| {
                if (a == b) all_distinct = false;
            }
        }
        if (all_distinct) return i;
    }
    return 0;
}

pub fn main() !void {
    const line = trim(u8, data, " \n\r\t");
    print("part 1: {d}\n", .{marker(line, 4)});
    print("part 2: {d}\n", .{marker(line, 14)});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
