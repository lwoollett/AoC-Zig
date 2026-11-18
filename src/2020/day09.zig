const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day09.txt");

pub fn main() !void {
    var nums: List(u64) = .empty;
    defer nums.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        try nums.append(gpa, try parseInt(u64, line, 10));
    }

    const preamble = 25;
    var invalid: u64 = 0;
    var invalid_idx: usize = 0;

    var i: usize = preamble;
    while (i < nums.items.len) : (i += 1) {
        const target = nums.items[i];
        var found = false;
        outer: for (nums.items[i - preamble .. i], 0..) |a, x| {
            for (nums.items[i - preamble + x + 1 .. i]) |b| {
                if (a + b == target) {
                    found = true;
                    break :outer;
                }
            }
        }
        if (!found) {
            invalid = target;
            invalid_idx = i;
            break;
        }
    }
    print("part 1: {d}\n", .{invalid});

    // part 2: contiguous range summing to `invalid`
    var lo: usize = 0;
    var hi: usize = 1;
    var sum: u64 = nums.items[0] + nums.items[1];
    while (hi < invalid_idx) {
        if (sum == invalid) {
            var min: u64 = std.math.maxInt(u64);
            var max: u64 = 0;
            for (nums.items[lo .. hi + 1]) |v| {
                min = @min(min, v);
                max = @max(max, v);
            }
            print("part 2: {d}\n", .{min + max});
            return;
        } else if (sum < invalid) {
            hi += 1;
            sum += nums.items[hi];
        } else {
            sum -= nums.items[lo];
            lo += 1;
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
