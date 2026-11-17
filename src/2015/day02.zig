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

pub fn main() !void {
    var paper: u64 = 0;
    var ribbon: u64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var dims = splitSca(u8, line, 'x');
        const l = try parseInt(u32, dims.next().?, 10);
        const w = try parseInt(u32, dims.next().?, 10);
        const h = try parseInt(u32, dims.next().?, 10);

        const lw: u64 = l * w;
        const wh: u64 = w * h;
        const hl: u64 = h * l;
        const slack = @min(lw, @min(wh, hl));
        paper += 2 * lw + 2 * wh + 2 * hl + slack;

        // ribbon: smallest perimeter + volume
        const mx = @max(l, @max(w, h));
        const perimeter = 2 * (@as(u64, l) + w + h - mx);
        ribbon += perimeter + l * w * h;
    }

    print("part 1: {d}\n", .{paper});
    print("part 2: {d}\n", .{ribbon});
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
