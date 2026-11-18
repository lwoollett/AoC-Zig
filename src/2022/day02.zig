const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day02.txt");

fn shapeScore(c: u8) u64 {
    return switch (c) {
        'A', 'X' => 1, // rock
        'B', 'Y' => 2, // paper
        else => 3, // scissors
    };
}

fn beats(a: u8, b: u8) bool {
    // a beats b: rock>scissors, paper>rock, scissors>paper
    return (a == 'A' and b == 'Z') or (a == 'B' and b == 'X') or (a == 'C' and b == 'Y') or
        (a == 'X' and b == 'C') or (a == 'Y' and b == 'A') or (a == 'Z' and b == 'B');
}

pub fn main() !void {
    var total1: u64 = 0;
    var total2: u64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const opp = line[0];
        const me = line[2];

        // part 1
        total1 += shapeScore(me);
        if (shapeScore(opp) == shapeScore(me)) {
            total1 += 3;
        } else if (beats(me, opp)) {
            total1 += 6;
        }

        // part 2: X = lose, Y = draw, Z = win
        const outcome = line[2]; // X/Y/Z
        const shapes = "ABC";
        var mine: u8 = 0;
        for (shapes) |s| {
            const i_win = beats(s, opp);
            const i_lose = beats(opp, s);
            if (outcome == 'X' and i_lose) mine = s;
            if (outcome == 'Y' and !i_win and !i_lose) mine = s;
            if (outcome == 'Z' and i_win) mine = s;
        }
        total2 += shapeScore(mine);
        if (outcome == 'Y') total2 += 3;
        if (outcome == 'Z') total2 += 6;
    }
    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{total2});
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
// Only unmodified days will be modified.
