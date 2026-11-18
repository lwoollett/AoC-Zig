const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day02.txt");

const limits = [3]u32{ 12, 13, 14 }; // red, green, blue

fn colorIndex(c: []const u8) usize {
    if (c[0] == 'r') return 0;
    if (c[0] == 'g') return 1;
    return 2;
}

pub fn main() !void {
    var total1: u64 = 0;
    var total2: u64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green"
        const colon = indexOf(u8, line, ':').?;
        const id = try parseInt(u32, line[5..colon], 10);

        var maxes = [3]u32{ 0, 0, 0 };
        var it = tokenizeAny(u8, line[colon + 1 ..], ",;");
        while (it.next()) |tok_raw| {
            const tok = trim(u8, tok_raw, " ");
            const sp = indexOf(u8, tok, ' ').?;
            const n = try parseInt(u32, tok[0..sp], 10);
            const ci = colorIndex(tok[sp + 1 ..]);
            maxes[ci] = @max(maxes[ci], n);
        }

        if (maxes[0] <= limits[0] and maxes[1] <= limits[1] and maxes[2] <= limits[2]) {
            total1 += id;
        }
        total2 += @as(u64, maxes[0]) * maxes[1] * maxes[2];
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
