const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day15.txt");

const max_value = 30_000_000;

pub fn main() !void {
    var start = try gpa.alloc(u32, 8);
    defer gpa.free(start);
    var n: usize = 0;
    var it = tokenizeSca(u8, trim(u8, data, " \n\r\t"), ',');
    while (it.next()) |tok| {
        start[n] = try parseInt(u32, tok, 10);
        n += 1;
    }

    // last-seen turn per value (0 = never)
    var seen = try gpa.alloc(u32, max_value + 1);
    defer gpa.free(seen);
    @memset(seen, 0);

    var turn: u32 = 1;
    var prev: u32 = 0;
    var part1: u32 = 0;

    for (start[0..n]) |v| {
        if (turn > 1) seen[prev] = turn - 1;
        prev = v;
        turn += 1;
        if (turn - 1 == 2020) part1 = v;
    }
    // continue the game
    while (turn <= max_value) : (turn += 1) {
        var next: u32 = 0;
        if (seen[prev] != 0) {
            next = turn - 1 - seen[prev];
        }
        seen[prev] = turn - 1;
        prev = next;
        if (turn == 2020) part1 = next;
    }
    // handle small inputs (< 2020 initial numbers) — prev now holds turn max_value's value
    print("part 1: {d}\n", .{part1});
    print("part 2: {d}\n", .{prev});
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
