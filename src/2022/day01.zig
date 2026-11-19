const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day01.txt");

pub fn main() !void {
    var sums: List(u64) = .empty;
    defer sums.deinit(gpa);
    var cur: u64 = 0;
    var lines = splitSca(u8, data, '\n');
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) {
            try sums.append(gpa, cur);
            cur = 0;
            continue;
        }
        cur += try parseInt(u64, line, 10);
    }
    try sums.append(gpa, cur);
    std.mem.sort(u64, sums.items, {}, comptime std.sort.desc(u64));
    print("part 1: {d}\n", .{sums.items[0]});
    print("part 2: {d}\n", .{sums.items[0] + sums.items[1] + sums.items[2]});
}

// Useful stdlib functions
const splitSca = std.mem.splitScalar;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
