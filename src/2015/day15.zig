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

const max_ingr = 4;
const max_props = 5; // capacity, durability, flavor, texture, calories

var props: [max_ingr][max_props]i64 = @splat(@splat(0));
var n_ingr: usize = 0;

fn scoreOf(amounts: [max_ingr]i64, need_calories: ?i64) i64 {
    var sums: [max_props]i64 = @splat(0);
    for (amounts, 0..) |a, i| {
        for (0..max_props) |p| sums[p] += a * props[i][p];
    }
    if (need_calories) |cal| {
        if (sums[4] != cal) return -1;
    }
    var score: i64 = 1;
    for (sums[0..4]) |s| {
        if (s <= 0) return 0;
        score *= s;
    }
    return score;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "Butterscotch: capacity -1, durability -2, flavor 6, texture 3, calories 8"
        var it = tokenizeAny(u8, line, " ,:");
        _ = it.next().?; // name
        for (0..max_props) |p| {
            _ = it.next().?; // property name
            props[n_ingr][p] = try parseInt(i64, it.next().?, 10);
        }
        n_ingr += 1;
    }

    var best: i64 = 0;
    var best500: i64 = 0;

    var a: i64 = 0;
    while (a <= 100) : (a += 1) {
        var b: i64 = 0;
        while (a + b <= 100) : (b += 1) {
            var c: i64 = 0;
            while (a + b + c <= 100) : (c += 1) {
                const d = 100 - a - b - c;
                const amounts = [max_ingr]i64{ a, b, c, d };
                best = @max(best, scoreOf(amounts, null));
                best500 = @max(best500, scoreOf(amounts, 500));
            }
        }
    }

    print("part 1: {d}\n", .{best});
    print("part 2: {d}\n", .{best500});
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
