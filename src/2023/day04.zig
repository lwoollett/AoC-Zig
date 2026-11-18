const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day04.txt");

pub fn main() !void {
    var total1: u64 = 0;
    var total2: u64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    var card_line: List(struct { matches: u32 }) = .empty;
    defer card_line.deinit(gpa);

    while (lines.next()) |line| {
        const colon = indexOf(u8, line, ':').?;
        const bar = indexOf(u8, line, '|').?;
        var winning = Map(u32, void).init(gpa);
        defer winning.deinit();
        var it = tokenizeAny(u8, line[colon + 1 .. bar], " ");
        while (it.next()) |tok| {
            try winning.put(try parseInt(u32, tok, 10), {});
        }
        var matches: u32 = 0;
        var it2 = tokenizeAny(u8, line[bar + 1 ..], " ");
        while (it2.next()) |tok| {
            const n = try parseInt(u32, tok, 10);
            if (winning.contains(n)) matches += 1;
        }
        if (matches > 0) {
            total1 += @as(u64, 1) << @intCast(matches - 1);
        }
        try card_line.append(gpa, .{ .matches = matches });
    }

    // part 2: copies
    const n = card_line.items.len;
    var counts = try gpa.alloc(u64, n);
    defer gpa.free(counts);
    @memset(counts, 1);
    for (0..n) |i| {
        const m = card_line.items[i].matches;
        var k: u32 = 1;
        while (k <= m and i + k < n) : (k += 1) {
            counts[i + k] += counts[i];
        }
    }
    for (counts) |c| total2 += c;

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
// Only unmodified days will be modified.
