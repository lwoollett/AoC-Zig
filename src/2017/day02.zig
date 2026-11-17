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

pub fn main() !void {
    var checksum: u32 = 0;
    var div_sum: u32 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var nums: List(u32) = .empty;
        defer nums.deinit(gpa);
        var it = tokenizeAny(u8, line, " \t");
        while (it.next()) |tok| {
            try nums.append(gpa, try parseInt(u32, tok, 10));
        }
        // part 1
        var mn: u32 = std.math.maxInt(u32);
        var mx: u32 = 0;
        for (nums.items) |v| {
            mn = @min(mn, v);
            mx = @max(mx, v);
        }
        checksum += mx - mn;
        // part 2
        outer: for (nums.items, 0..) |a, i| {
            for (nums.items, 0..) |b, j| {
                if (i == j) continue;
                if (a > b and a % b == 0) {
                    div_sum += a / b;
                    break :outer;
                }
            }
        }
    }

    print("part 1: {d}\n", .{checksum});
    print("part 2: {d}\n", .{div_sum});
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
