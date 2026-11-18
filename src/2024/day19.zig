const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day19.txt");

var towels: List([]const u8) = .empty;

fn ways(design: []const u8, memo: *StrMap(u64)) !u64 {
    if (design.len == 0) return 1;
    if (memo.get(design)) |v| return v;
    var total: u64 = 0;
    for (towels.items) |t| {
        if (design.len >= t.len and std.mem.startsWith(u8, design, t)) {
            total += try ways(design[t.len..], memo);
        }
    }
    try memo.put(design, total);
    return total;
}

pub fn main() !void {
    var designs: List([]const u8) = .empty;
    defer designs.deinit(gpa);

    var lines = splitSca(u8, data, '\n');
    {
        const first = lines.next().?;
        var it = tokenizeSca(u8, first, ',');
        while (it.next()) |tok| {
            try towels.append(gpa, trim(u8, tok, " "));
        }
    }
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) continue;
        try designs.append(gpa, line);
    }

    var count: u64 = 0;
    var total: u64 = 0;
    var memo = StrMap(u64).init(gpa);
    defer memo.deinit();
    for (designs.items) |d| {
        const w = try ways(d, &memo);
        if (w > 0) count += 1;
        total += w;
    }
    print("part 1: {d}\n", .{count});
    print("part 2: {d}\n", .{total});
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
