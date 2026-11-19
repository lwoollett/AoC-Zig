const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day17.txt");

pub fn main() !void {
    const step = try parseInt(usize, trim(u8, data, " \n\r\t"), 10);

    // Part 1: simulate the actual buffer (2017 insertions).
    var buf: List(u32) = .empty;
    defer buf.deinit(gpa);
    try buf.append(gpa, 0);
    var pos: usize = 0;
    var value: u32 = 1;
    while (value <= 2017) : (value += 1) {
        pos = (pos + step) % buf.items.len;
        try buf.insert(gpa, pos + 1, value);
        pos += 1;
    }
    print("part 1: {d}\n", .{buf.items[(pos + 1) % buf.items.len]});

    // Part 2: 50M insertions — only track what lands after 0.
    // 0 never moves from index 0, so watch insertions at index 1.
    // (add + conditional subtract instead of % — 50M divisions add up)
    var after_zero: u32 = 0;
    var len: usize = 1;
    pos = 0;
    value = 1;
    while (value <= 50_000_000) : (value += 1) {
        pos += step;
        while (pos >= len) pos -= len; // step < len after warmup, so this is 1-2 iterations
        if (pos == 0) after_zero = value; // inserted right after 0
        pos += 1;
        len += 1;
    }
    print("part 2: {d}\n", .{after_zero});
}

// Useful stdlib functions
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
