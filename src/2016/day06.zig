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
    var lines = tokenizeAny(u8, data, "\n");

    const first = lines.next().?;
    const width = first.len;
    var counts = try gpa.alloc([26]u32, width);
    defer gpa.free(counts);
    @memset(counts, @splat(0));

    for (first, 0..) |c, i| counts[i][c - 'a'] += 1;
    while (lines.next()) |line| {
        for (line, 0..) |c, i| {
            counts[i][c - 'a'] += 1;
        }
    }

    var most: [64]u8 = undefined;
    var least: [64]u8 = undefined;
    for (counts, 0..) |col, i| {
        var mi: usize = 0;
        for (col, 0..) |n, j| {
            if (n > col[mi]) mi = j;
        }
        var li: usize = 0;
        var seen_nonzero = false;
        for (col, 0..) |n, j| {
            if (n == 0) continue;
            if (!seen_nonzero or n < col[li]) {
                li = j;
                seen_nonzero = true;
            }
        }
        most[i] = @intCast('a' + mi);
        least[i] = @intCast('a' + li);
    }

    print("part 1: {s}\n", .{most[0..counts.len]});
    print("part 2: {s}\n", .{least[0..counts.len]});
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
