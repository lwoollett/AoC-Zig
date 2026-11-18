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
    var nums: List(u32) = .empty;
    defer nums.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        try nums.append(gpa, try parseInt(u32, line, 10));
    }

    // part 1: pair summing to 2020
    for (nums.items, 0..) |a, i| {
        for (nums.items[i + 1 ..]) |b| {
            if (a + b == 2020) {
                print("part 1: {d}\n", .{a * b});
            }
        }
    }

    // part 2: triple summing to 2020
    outer: for (nums.items, 0..) |a, i| {
        for (nums.items[i + 1 ..], 0..) |b, j| {
            if (a + b >= 2020) continue;
            const c = 2020 - a - b;
            for (nums.items[i + j + 2 ..]) |d| {
                if (d == c) {
                    print("part 2: {d}\n", .{a * b * c});
                    break :outer;
                }
            }
        }
    }
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
