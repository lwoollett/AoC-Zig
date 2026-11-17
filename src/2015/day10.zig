const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day10.txt");

fn lookAndSay(input: []const u8, out: *List(u8)) !void {
    out.clearRetainingCapacity();
    var i: usize = 0;
    while (i < input.len) {
        var j = i;
        while (j < input.len and input[j] == input[i]) j += 1;
        const run_len = j - i;
        var digits: [20]u8 = undefined;
        const n_str = std.fmt.bufPrint(&digits, "{d}{c}", .{ run_len, input[i] }) catch unreachable;
        try out.appendSlice(gpa, n_str);
        i = j;
    }
}

pub fn main() !void {
    const start = trim(u8, data, " \n\r\t");

    var cur: List(u8) = .empty;
    defer cur.deinit(gpa);
    var next: List(u8) = .empty;
    defer next.deinit(gpa);

    try cur.appendSlice(gpa, start);

    var i: usize = 0;
    while (i < 50) : (i += 1) {
        try lookAndSay(cur.items, &next);
        std.mem.swap(List(u8), &cur, &next);
        if (i == 39) {
            print("part 1: {d}\n", .{cur.items.len});
        }
    }
    print("part 2: {d}\n", .{cur.items.len});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.findScalar;
const indexOfAny = std.mem.findAny;
const indexOfStr = std.mem.findPos;
const lastIndexOf = std.mem.findScalarLast;
const lastIndexOfAny = std.mem.findLastAny;
const lastIndexOfStr = std.mem.findLastLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
