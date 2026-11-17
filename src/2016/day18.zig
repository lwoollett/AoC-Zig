const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day18.txt");

fn countSafe(first: []const u8, rows: usize) !u64 {
    const width = first.len;
    var cur = try gpa.alloc(u8, width);
    defer gpa.free(cur);
    var next = try gpa.alloc(u8, width);
    defer gpa.free(next);
    @memcpy(cur, first);

    var safe: u64 = 0;
    for (cur) |c| {
        if (c == '.') safe += 1;
    }

    var row: usize = 1;
    while (row < rows) : (row += 1) {
        for (0..width) |i| {
            const left: u8 = if (i == 0) '.' else cur[i - 1];
            const right: u8 = if (i + 1 == width) '.' else cur[i + 1];
            next[i] = if (left != right) '^' else '.';
            if (next[i] == '.') safe += 1;
        }
        std.mem.swap([]u8, &cur, &next);
    }
    return safe;
}

pub fn main() !void {
    const first = trim(u8, data, " \n\r\t");
    print("part 1: {d}\n", .{try countSafe(first, 40)});
    print("part 2: {d}\n", .{try countSafe(first, 400_000)});
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
