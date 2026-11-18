const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day01.txt");

pub fn main() !void {
    var left: List(u64) = .empty;
    var right: List(u64) = .empty;
    defer left.deinit(gpa);
    defer right.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const sp = indexOfAny(u8, line, " \t").?;
        try left.append(gpa, try parseInt(u64, line[0..sp], 10));
        var it = tokenizeAny(u8, line[sp..], " \t");
        try right.append(gpa, try parseInt(u64, it.next().?, 10));
    }

    std.mem.sort(u64, left.items, {}, comptime std.sort.asc(u64));
    std.mem.sort(u64, right.items, {}, comptime std.sort.asc(u64));

    var total1: u64 = 0;
    for (left.items, right.items) |a, b| {
        total1 += if (a > b) a - b else b - a;
    }
    print("part 1: {d}\n", .{total1});

    var counts = Map(u64, u64).init(gpa);
    defer counts.deinit();
    for (right.items) |b| {
        const gop = try counts.getOrPut(b);
        if (!gop.found_existing) gop.value_ptr.* = 0;
        gop.value_ptr.* += 1;
    }
    var total2: u64 = 0;
    for (left.items) |a| {
        total2 += a * (counts.get(a) orelse 0);
    }
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
// Only unmodified days will be updated.
