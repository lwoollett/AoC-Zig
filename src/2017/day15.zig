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

const fa: u64 = 16807;
const fb: u64 = 48271;
const mask: u64 = 2147483647;
const low16: u64 = 0xffff;

fn lastInt(line: []const u8) []const u8 {
    var last: []const u8 = "";
    var it = tokenizeAny(u8, line, " ");
    while (it.next()) |t| last = t;
    return last;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    const line_a = lines.next().?;
    const line_b = lines.next().?;
    var a = try parseInt(u64, lastInt(line_a), 10);
    var b = try parseInt(u64, lastInt(line_b), 10);

    // Part 1: 40M plain pairs.
    var count: u32 = 0;
    var i: u64 = 0;
    while (i < 40_000_000) : (i += 1) {
        a = a * fa % mask;
        b = b * fb % mask;
        if (a & low16 == b & low16) count += 1;
    }
    print("part 1: {d}\n", .{count});

    // Part 2: 5M picky pairs.
    count = 0;
    a = try parseInt(u64, lastInt(line_a), 10);
    b = try parseInt(u64, lastInt(line_b), 10);
    i = 0;
    while (i < 5_000_000) : (i += 1) {
        while (true) {
            a = a * fa % mask;
            if (a % 4 == 0) break;
        }
        while (true) {
            b = b * fb % mask;
            if (b % 8 == 0) break;
        }
        if (a & low16 == b & low16) count += 1;
    }
    print("part 2: {d}\n", .{count});
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
