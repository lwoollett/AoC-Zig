const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day09.txt");

pub fn main() !void {
    var depth: u32 = 0;
    var score: u64 = 0;
    var garbage: u64 = 0;
    var in_garbage = false;

    var i: usize = 0;
    const s = trim(u8, data, " \n\r\t");
    while (i < s.len) : (i += 1) {
        const c = s[i];
        if (in_garbage) {
            switch (c) {
                '!' => i += 1, // skip next
                '>' => in_garbage = false,
                else => garbage += 1,
            }
        } else {
            switch (c) {
                '{' => {
                    depth += 1;
                    score += depth;
                },
                '}' => depth -= 1,
                '<' => in_garbage = true,
                else => {},
            }
        }
    }

    print("part 1: {d}\n", .{score});
    print("part 2: {d}\n", .{garbage});
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
