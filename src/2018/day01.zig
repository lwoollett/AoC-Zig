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
    var total: i64 = 0;
    var lines0 = tokenizeAny(u8, data, "\n");
    while (lines0.next()) |line| {
        total += try parseInt(i64, line, 10);
    }

    var sum: i64 = 0;
    var seen = Map(i64, void).init(gpa);
    defer seen.deinit();
    var repeat: ?i64 = null;

    outer: while (repeat == null) {
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            const v = try parseInt(i64, line, 10);
            sum += v;
            if (repeat == null and seen.contains(sum)) {
                repeat = sum;
                break :outer;
            }
            try seen.put(sum, {});
        }
    }

    print("part 1: {d}\n", .{total});
    print("part 2: {d}\n", .{repeat.?});
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
