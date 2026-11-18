const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day07.txt");

pub fn main() !void {
    var crabs: List(i64) = .empty;
    defer crabs.deinit(gpa);
    var it = tokenizeSca(u8, trim(u8, data, " \n\r\t"), ',');
    while (it.next()) |tok| {
        try crabs.append(gpa, try parseInt(i64, tok, 10));
    }

    var min_p1: i64 = std.math.maxInt(i64);
    var min_p2: i64 = std.math.maxInt(i64);
    var lo: i64 = std.math.maxInt(i64);
    var hi: i64 = std.math.minInt(i64);
    for (crabs.items) |c| {
        lo = @min(lo, c);
        hi = @max(hi, c);
    }
    var pos = lo;
    while (pos <= hi) : (pos += 1) {
        var f1: i64 = 0;
        var f2: i64 = 0;
        for (crabs.items) |c| {
            const d: i64 = @intCast(@abs(pos - c));
            f1 += d;
            f2 += @divTrunc(d * (d + 1), 2);
        }
        min_p1 = @min(min_p1, f1);
        min_p2 = @min(min_p2, f2);
    }
    print("part 1: {d}\n", .{min_p1});
    print("part 2: {d}\n", .{min_p2});
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
