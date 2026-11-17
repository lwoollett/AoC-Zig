const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day06.txt");

pub fn main() !void {
    var banks: List(u32) = .empty;
    defer banks.deinit(gpa);
    var it = tokenizeAny(u8, data, " \t\n");
    while (it.next()) |tok| {
        try banks.append(gpa, try parseInt(u32, tok, 10));
    }
    const n = banks.items.len;

    var seen = StrMap(u64).init(gpa);
    defer seen.deinit();

    var steps: u64 = 0;
    var first_seen: u64 = 0;
    while (true) {
        var buf: [512]u8 = undefined;
        var fbs = std.Io.Writer.fixed(&buf);
        for (banks.items, 0..) |b, i| {
            if (i > 0) fbs.writeByte(' ') catch {};
            fbs.print("{d}", .{b}) catch {};
        }
        const key = fbs.buffer[0..fbs.end];
        if (seen.get(key)) |at| {
            first_seen = at;
            break;
        }
        try seen.put(try gpa.dupe(u8, key), steps);

        // redistribute the largest bank
        var mi: usize = 0;
        for (banks.items, 0..) |b, i| {
            if (b > banks.items[mi]) mi = i;
        }
        var blocks = banks.items[mi];
        banks.items[mi] = 0;
        var idx = mi;
        while (blocks > 0) : (blocks -= 1) {
            idx = (idx + 1) % n;
            banks.items[idx] += 1;
        }
        steps += 1;
    }

    print("part 1: {d}\n", .{steps});
    print("part 2: {d}\n", .{steps - first_seen});
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
