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

fn reacts(a: u8, b: u8) bool {
    return (a | 0x20) == (b | 0x20) and a != b;
}

/// Reduce polymer with a stack; `skip` removes one letter type (both cases).
fn reducedLen(input: []const u8, skip: u8) !usize {
    var stack: List(u8) = .empty;
    defer stack.deinit(gpa);
    for (input) |c| {
        if ((c | 0x20) == skip) continue;
        if (stack.items.len > 0 and reacts(stack.items[stack.items.len - 1], c)) {
            _ = stack.pop();
        } else {
            try stack.append(gpa, c);
        }
    }
    return stack.items.len;
}

pub fn main() !void {
    const polymer = trim(u8, data, " \n\r\t");

    print("part 1: {d}\n", .{try reducedLen(polymer, 0)});

    var best: usize = std.math.maxInt(usize);
    var letter: u8 = 'a';
    while (letter <= 'z') : (letter += 1) {
        best = @min(best, try reducedLen(polymer, letter));
    }
    print("part 2: {d}\n", .{best});
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
