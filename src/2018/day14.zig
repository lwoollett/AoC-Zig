const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day14.txt");

fn run(input: []const u8) !u64 {
    // target as raw digit values (0-9), matching the recipe list
    var target_buf: [16]u8 = undefined;
    const target_seq = target_buf[0..input.len];
    for (input, 0..) |c, i| target_seq[i] = c - '0';

    var recipes: List(u8) = .empty;
    defer recipes.deinit(gpa);
    try recipes.append(gpa, 3);
    try recipes.append(gpa, 7);
    var e1: usize = 0;
    var e2: usize = 1;

    while (true) {
        const sum = recipes.items[e1] + recipes.items[e2];
        if (sum >= 10) {
            try recipes.append(gpa, 1);
            try recipes.append(gpa, sum - 10);
        } else {
            try recipes.append(gpa, sum);
        }
        e1 = (e1 + 1 + recipes.items[e1]) % recipes.items.len;
        e2 = (e2 + 1 + recipes.items[e2]) % recipes.items.len;

        // check for the target sequence at the tail
        if (recipes.items.len >= target_seq.len + 1) {
            const tail = recipes.items[recipes.items.len - target_seq.len ..][0..target_seq.len];
            const tail2 = recipes.items[recipes.items.len - target_seq.len - 1 ..][0..target_seq.len];
            if (std.mem.eql(u8, tail, target_seq)) {
                return recipes.items.len - target_seq.len;
            }
            if (std.mem.eql(u8, tail2, target_seq)) {
                return recipes.items.len - target_seq.len - 1;
            }
        }
    }
}

pub fn main() !void {
    const input = trim(u8, data, " \n\r\t");
    const n_recipes = try parseInt(u64, input, 10);

    // part 1: ten scores after n_recipes
    var recipes: List(u8) = .empty;
    defer recipes.deinit(gpa);
    try recipes.append(gpa, 3);
    try recipes.append(gpa, 7);
    var e1: usize = 0;
    var e2: usize = 1;
    while (recipes.items.len < n_recipes + 10) {
        const sum = recipes.items[e1] + recipes.items[e2];
        if (sum >= 10) {
            try recipes.append(gpa, 1);
            try recipes.append(gpa, sum - 10);
        } else {
            try recipes.append(gpa, sum);
        }
        e1 = (e1 + 1 + recipes.items[e1]) % recipes.items.len;
        e2 = (e2 + 1 + recipes.items[e2]) % recipes.items.len;
    }
    var result: [10]u8 = undefined;
    for (0..10) |i| {
        result[i] = '0' + recipes.items[n_recipes + i];
    }
    print("part 1: {s}\n", .{result});

    // part 2: index of the input sequence
    print("part 2: {d}\n", .{try run(input)});
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
