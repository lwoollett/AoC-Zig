const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

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
