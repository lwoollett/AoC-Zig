const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day11.txt");

var adj = StrMap(*List([]const u8)).init(std.heap.page_allocator);
var memo = StrMap(u64).init(std.heap.page_allocator);

fn countPaths(name: []const u8) !u64 {
    if (memo.get(name)) |v| return v;
    if (std.mem.eql(u8, name, "out")) return 1;
    var total: u64 = 0;
    if (adj.get(name)) |neighbors| {
        for (neighbors.items) |nb| {
            total += try countPaths(nb);
        }
    }
    try memo.put(name, total);
    return total;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const colon = indexOf(u8, line, ':').?;
        const src = try std.heap.page_allocator.dupe(u8, line[0..colon]);
        const gop = try adj.getOrPut(src);
        if (!gop.found_existing) {
            const l = try std.heap.page_allocator.create(List([]const u8));
            l.* = .empty;
            gop.value_ptr.* = l;
        }
        var it = tokenizeSca(u8, line[colon + 1 ..], ' ');
        while (it.next()) |tok| {
            try gop.value_ptr.*.append(std.heap.page_allocator, try std.heap.page_allocator.dupe(u8, tok));
        }
    }

    print("part 1: {d}\n", .{try countPaths("you")});
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
