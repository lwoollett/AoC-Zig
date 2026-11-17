const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day01.txt");

fn fuel(mass: i64) i64 {
    return @divTrunc(mass, 3) - 2;
}

pub fn main() !void {
    var total: i64 = 0;
    var total_recursive: i64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const mass = try parseInt(i64, line, 10);
        const f = fuel(mass);
        total += f;
        // p2: keep fueling the fuel
        var extra = fuel(f);
        while (extra > 0) {
            total_recursive += extra;
            extra = fuel(extra);
        }
        total_recursive += f;
    }

    print("part 1: {d}\n", .{total});
    print("part 2: {d}\n", .{total_recursive});
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
