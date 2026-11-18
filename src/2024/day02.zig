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

fn safe(nums: []const i64) bool {
    var inc = true;
    var dec = true;
    for (nums[1..], 0..) |v, i| {
        const d = v - nums[i];
        if (d == 0 or @abs(d) > 3) return false;
        if (d < 0) inc = false;
        if (d > 0) dec = false;
    }
    return inc or dec;
}

fn safeDampened(nums: []const i64) bool {
    if (safe(nums)) return true;
    var buf: [16]i64 = undefined;
    for (0..nums.len) |skip| {
        var n: usize = 0;
        for (nums, 0..) |v, i| {
            if (i == skip) continue;
            buf[n] = v;
            n += 1;
        }
        if (safe(buf[0..n])) return true;
    }
    return false;
}

pub fn main() !void {
    var count1: u32 = 0;
    var count2: u32 = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var nums: List(i64) = .empty;
        defer nums.deinit(gpa);
        var it = tokenizeSca(u8, line, ' ');
        while (it.next()) |tok| {
            try nums.append(gpa, try parseInt(i64, tok, 10));
        }
        if (safe(nums.items)) count1 += 1;
        if (safeDampened(nums.items)) count2 += 1;
    }
    print("part 1: {d}\n", .{count1});
    print("part 2: {d}\n", .{count2});
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
