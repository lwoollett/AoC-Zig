const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day05.txt");

fn run(strict: bool) !u64 {
    var jumps: List(i64) = .empty;
    defer jumps.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        try jumps.append(gpa, try parseInt(i64, line, 10));
    }
    var pc: i64 = 0;
    var steps: u64 = 0;
    while (pc >= 0 and pc < jumps.items.len) {
        const i: usize = @intCast(pc);
        const off = jumps.items[i];
        if (strict) {
            jumps.items[i] = if (off >= 3) off - 1 else off + 1;
        } else {
            jumps.items[i] = off + 1;
        }
        pc += off;
        steps += 1;
    }
    return steps;
}

pub fn main() !void {
    print("part 1: {d}\n", .{try run(false)});
    print("part 2: {d}\n", .{try run(true)});
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
