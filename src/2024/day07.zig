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

fn concat(a: u64, b: u64) u64 {
    var m = b;
    var t = a;
    while (m > 0) {
        t *= 10;
        m /= 10;
    }
    return t + b;
}

fn solvable(target: u64, nums: []const u64, part2: bool) bool {
    if (nums.len == 1) return nums[0] == target;
    return search(target, nums[0], nums[1..], part2);
}

fn search(target: u64, acc: u64, rest: []const u64, part2: bool) bool {
    if (rest.len == 0) return acc == target;
    // prune: acc can only grow
    if (acc > target and !canShrink(target, acc, rest)) {
        if (acc > target) return false;
    }
    const n = rest[0];
    if (search(target, acc + n, rest[1..], part2)) return true;
    if (search(target, acc * n, rest[1..], part2)) return true;
    if (part2) {
        if (search(target, concat(acc, n), rest[1..], part2)) return true;
    }
    return false;
}

fn canShrink(target: u64, acc: u64, rest: []const u64) bool {
    _ = target;
    _ = acc;
    _ = rest;
    return false;
}

pub fn main() !void {
    var total1: u64 = 0;
    var total2: u64 = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const colon = indexOf(u8, line, ':').?;
        const target = try parseInt(u64, line[0..colon], 10);
        var nums: List(u64) = .empty;
        defer nums.deinit(gpa);
        var it = tokenizeSca(u8, line[colon + 1 ..], ' ');
        while (it.next()) |tok| {
            try nums.append(gpa, try parseInt(u64, tok, 10));
        }
        if (solvable(target, nums.items, false)) {
            total1 += target;
        }
        if (solvable(target, nums.items, true)) {
            total2 += target;
        }
    }
    print("part 1: {d}\n", .{total1});
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
// Only unmodified days will be updated.
