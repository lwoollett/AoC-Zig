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

fn wins(t: u64, d: u64) u64 {
    var count: u64 = 0;
    var h: u64 = 1;
    while (h < t) : (h += 1) {
        if (h * (t - h) > d) count += 1;
    }
    return count;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    const time_line = lines.next().?;
    const dist_line = lines.next().?;

    // part 1
    var product: u64 = 1;
    {
        var tit = tokenizeAny(u8, time_line[6..], " ");
        var dit = tokenizeAny(u8, dist_line[9..], " ");
        while (tit.next()) |tt| {
            const dd = dit.next().?;
            const t = try parseInt(u64, tt, 10);
            const d = try parseInt(u64, dd, 10);
            const n = wins(t, d);
            if (n > 0) product *= n;
        }
    }
    print("part 1: {d}\n", .{product});

    // part 2: concatenated
    var t2: u64 = 0;
    var d2: u64 = 0;
    {
        var tit = tokenizeAny(u8, time_line[6..], " ");
        while (tit.next()) |tt| {
            for (tt) |c| {
                t2 = t2 * 10 + (c - '0');
            }
        }
        var dit = tokenizeAny(u8, dist_line[9..], " ");
        while (dit.next()) |dd| {
            for (dd) |c| {
                d2 = d2 * 10 + (c - '0');
            }
        }
    }
    print("part 2: {d}\n", .{wins(t2, d2)});
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
