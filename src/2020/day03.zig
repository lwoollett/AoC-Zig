const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day03.txt");

fn countTrees(lines: []const []const u8, dx: usize, dy: usize) u64 {
    var trees: u64 = 0;
    var x: usize = 0;
    var y: usize = 0;
    while (y < lines.len) : (y += dy) {
        const line = lines[y];
        if (line[x % line.len] == '#') trees += 1;
        x += dx;
    }
    return trees;
}

pub fn main() !void {
    var lines: List([]const u8) = .empty;
    defer lines.deinit(gpa);
    var it = tokenizeAny(u8, data, "\n");
    while (it.next()) |line| {
        try lines.append(gpa, line);
    }

    print("part 1: {d}\n", .{countTrees(lines.items, 3, 1)});

    const slopes = [_][2]usize{
        .{ 1, 1 }, .{ 3, 1 }, .{ 5, 1 }, .{ 7, 1 }, .{ 1, 2 },
    };
    var product: u64 = 1;
    for (slopes) |s| {
        product *= countTrees(lines.items, s[0], s[1]);
    }
    print("part 2: {d}\n", .{product});
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
