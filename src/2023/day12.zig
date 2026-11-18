const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day12.txt");

var spring: []const u8 = undefined;
var groups: List(u32) = .empty;
var memo: ?Map([3]i64, i64) = null;

fn count(pos: i64, gi: i64, cur_len: i64) anyerror!i64 {
    const key = [3]i64{ pos, gi, cur_len };
    if (memo.?.get(key)) |v| return v;

    var result: i64 = 0;
    if (pos == @as(i64, @intCast(spring.len))) {
        // done: all groups complete?
        if (gi == groups.items.len and cur_len == 0) return 1;
        if (gi == groups.items.len - 1 and cur_len == groups.items[@intCast(gi)]) return 1;
        return 0;
    }
    const c = spring[@intCast(pos)];
    // try '.'
    if (c == '.' or c == '?') {
        if (cur_len == 0) {
            result += try count(pos + 1, gi, 0);
        } else if (gi < groups.items.len and cur_len == groups.items[@intCast(gi)]) {
            result += try count(pos + 1, gi + 1, 0);
        }
    }
    // try '#'
    if (c == '#' or c == '?') {
        if (gi < groups.items.len and cur_len < groups.items[@intCast(gi)]) {
            result += try count(pos + 1, gi, cur_len + 1);
        }
    }
    try memo.?.put(key, result);
    return result;
}

fn solveLine(line: []const u8, copies: usize) !i64 {
    const sp = indexOf(u8, line, ' ').?;
    const base = line[0..sp];
    groups.clearRetainingCapacity();
    var it = tokenizeSca(u8, line[sp + 1 ..], ',');
    while (it.next()) |tok| {
        try groups.append(gpa, try parseInt(u32, tok, 10));
    }

    // unfold
    var sb: List(u8) = .empty;
    defer sb.deinit(gpa);
    var gb: List(u32) = .empty;
    defer gb.deinit(gpa);
    for (0..copies) |k| {
        if (k > 0) try sb.append(gpa, '?');
        try sb.appendSlice(gpa, base);
        for (groups.items) |g| {
            try gb.append(gpa, g);
        }
    }
    groups.clearRetainingCapacity();
    try groups.appendSlice(gpa, gb.items);
    spring = sb.items;

    memo = Map([3]i64, i64).init(gpa);
    defer memo.?.deinit();
    return count(0, 0, 0);
}

pub fn main() !void {
    var total1: i64 = 0;
    var total2: i64 = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        total1 += try solveLine(line, 1);
    }
    print("part 1: {d}\n", .{total1});

    lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        total2 += try solveLine(line, 5);
    }
    print("part 2: {d}\n", .{total2});
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
