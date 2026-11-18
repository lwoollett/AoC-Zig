const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day25.txt");

const subject = 7;
const modulus: u64 = 20201227;

fn transform(sub: u64, loops: u64) u64 {
    var v: u64 = 1;
    var i: u64 = 0;
    while (i < loops) : (i += 1) {
        v = v * sub % modulus;
    }
    return v;
}

fn loopSize(pk: u64) u64 {
    var v: u64 = 1;
    var i: u64 = 0;
    while (true) : (i += 1) {
        if (v == pk) return i;
        v = v * subject % modulus;
    }
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    const card_pk = try parseInt(u64, lines.next().?, 10);
    const door_pk = try parseInt(u64, lines.next().?, 10);

    const card_loops = loopSize(card_pk);
    const key = transform(door_pk, card_loops);
    print("part 1: {d}\n", .{key});
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
