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

fn isTriangle(a: u32, b: u32, c: u32) bool {
    return a + b > c and b + c > a and a + c > b;
}

pub fn main() !void {
    var count1: u32 = 0;
    var count2: u32 = 0;

    var rows: [3][3]u32 = undefined;
    var n_rows: usize = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, " ");
        const a = try parseInt(u32, it.next().?, 10);
        const b = try parseInt(u32, it.next().?, 10);
        const c = try parseInt(u32, it.next().?, 10);

        if (isTriangle(a, b, c)) count1 += 1;

        // part 2: read vertically, in groups of three rows
        rows[n_rows] = .{ a, b, c };
        n_rows += 1;
        if (n_rows == 3) {
            for (0..3) |col| {
                if (isTriangle(rows[0][col], rows[1][col], rows[2][col])) count2 += 1;
            }
            n_rows = 0;
        }
    }

    print("part 1: {d}\n", .{count1});
    print("part 2: {d}\n", .{count2});
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
