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

/// Version 2 length: markers apply recursively, nothing materialized.
fn v2len(s: []const u8) u64 {
    var total: u64 = 0;
    var i: usize = 0;
    while (i < s.len) {
        if (s[i] == '(') {
            const close = std.mem.findScalar(u8, s[i..], ')').?;
            const inner = s[i + 1 .. i + close];
            const x = std.mem.findScalar(u8, inner, 'x').?;
            const count = parseInt(u32, inner[0..x], 10) catch 0;
            const times = parseInt(u32, inner[x + 1 ..], 10) catch 0;
            const span = @min(@as(usize, count), s.len - (i + close + 1));
            total += v2len(s[i + close + 1 .. i + close + 1 + span]) * times;
            i += close + 1 + span;
        } else {
            total += 1;
            i += 1;
        }
    }
    return total;
}

pub fn main() !void {
    const input = trim(u8, data, " \n\r\t");

    // Part 1: materialized decompression (one pass, no recursion).
    var out: List(u8) = .empty;
    defer out.deinit(gpa);
    var i: usize = 0;
    while (i < input.len) {
        if (input[i] == '(') {
            const close = std.mem.findScalar(u8, input[i..], ')').?;
            const inner = input[i + 1 .. i + close];
            const x = std.mem.findScalar(u8, inner, 'x').?;
            const count = parseInt(u32, inner[0..x], 10) catch 0;
            const times = parseInt(u32, inner[x + 1 ..], 10) catch 0;
            const span = @min(@as(usize, count), input.len - (i + close + 1));
            var t: u32 = 0;
            while (t < times) : (t += 1) {
                try out.appendSlice(gpa, input[i + close + 1 .. i + close + 1 + span]);
            }
            i += close + 1 + span;
        } else {
            try out.append(gpa, input[i]);
            i += 1;
        }
    }

    print("part 1: {d}\n", .{out.items.len});
    print("part 2: {d}\n", .{v2len(input)});
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
