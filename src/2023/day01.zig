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

const words = [_][]const u8{ "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

fn calibration(line: []const u8, comptime words_on: bool) u32 {
    var first: u32 = 0;
    var last: u32 = 0;
    var found_first = false;

    for (line, 0..) |c, i| {
        var d: ?u32 = null;
        if (c >= '0' and c <= '9') {
            d = c - '0';
        } else if (words_on) {
            for (words, 0..) |wd, wi| {
                if (std.mem.startsWith(u8, line[i..], wd)) {
                    d = @intCast(wi);
                    break;
                }
            }
        }
        if (d) |v| {
            if (!found_first) {
                first = v;
                found_first = true;
            }
            last = v;
        }
    }
    return first * 10 + last;
}

pub fn main() !void {
    var t1: u32 = 0;
    var t2: u32 = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        t1 += calibration(line, false);
        t2 += calibration(line, true);
    }
    print("part 1: {d}\n", .{t1});
    print("part 2: {d}\n", .{t2});
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
// Only unmodified days will be modified.
