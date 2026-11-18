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

fn seatId(pass: []const u8) u32 {
    var id: u32 = 0;
    for (pass) |c| {
        id <<= 1;
        if (c == 'B' or c == 'R') id |= 1;
    }
    return id;
}

pub fn main() !void {
    var ids: List(u32) = .empty;
    defer ids.deinit(gpa);
    var max_id: u32 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const id = seatId(line);
        max_id = @max(max_id, id);
        try ids.append(gpa, id);
    }
    print("part 1: {d}\n", .{max_id});

    std.mem.sort(u32, ids.items, {}, comptime std.sort.asc(u32));
    for (ids.items, 0..) |id, i| {
        if (i > 0 and id == ids.items[i - 1] + 2) {
            print("part 2: {d}\n", .{id - 1});
            return;
        }
    }
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
