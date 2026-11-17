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

pub fn main() !void {
    var x: i32 = 0;
    var y: i32 = 0;
    var dx: i32 = 0;
    var dy: i32 = 1; // facing north

    var visited = Map([2]i32, void).init(gpa);
    defer visited.deinit();
    try visited.put(.{ 0, 0 }, {});
    var repeated: ?[2]i32 = null;

    var toks = tokenizeAny(u8, data, " ,\n");
    while (toks.next()) |tok| {
        const turn = tok[0];
        const steps = try parseInt(i32, tok[1..], 10);
        // rotate
        const ndx = if (turn == 'R') dy else -dy;
        const ndy = if (turn == 'R') -dx else dx;
        dx = ndx;
        dy = ndy;
        var s: i32 = 0;
        while (s < steps) : (s += 1) {
            x += dx;
            y += dy;
            if (repeated == null and visited.contains(.{ x, y })) {
                repeated = .{ x, y };
            }
            try visited.put(.{ x, y }, {});
        }
    }

    print("part 1: {d}\n", .{@abs(x) + @abs(y)});
    if (repeated) |r| {
        print("part 2: {d}\n", .{@abs(r[0]) + @abs(r[1])});
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
