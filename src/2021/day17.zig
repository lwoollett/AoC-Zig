const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day17.txt");

// "target area: x=20..30, y=-10..-5"
var tx0: i64 = 0;
var tx1: i64 = 0;
var ty0: i64 = 0;
var ty1: i64 = 0;

fn hits(vx0: i64, vy0: i64) bool {
    var x: i64 = 0;
    var y: i64 = 0;
    var vx = vx0;
    var vy = vy0;
    while (true) {
        x += vx;
        y += vy;
        if (vx > 0) vx -= 1 else if (vx < 0) vx += 1;
        vy -= 1;
        if (x >= tx0 and x <= tx1 and y >= ty0 and y <= ty1) return true;
        if (vy < 0 and y < ty0) return false; // below target, falling
        if (vx == 0 and (x < tx0 or x > tx1)) return false; // no horizontal motion
    }
}

pub fn main() !void {
    // parse "target area: x=A..B, y=C..D"
    {
        const line = trim(u8, data, " \r\n");
        const dotdot = std.mem.indexOf(u8, line, "..").?;
        const comma = std.mem.indexOf(u8, line, ",").?;
        const dotdot2 = std.mem.indexOfPos(u8, line, comma, "..").?;
        tx0 = try parseInt(i64, line[std.mem.indexOf(u8, line, "x=").? + 2 .. dotdot], 10);
        tx1 = try parseInt(i64, line[dotdot + 2 .. comma], 10);
        ty0 = try parseInt(i64, line[std.mem.indexOf(u8, line, "y=").? + 2 .. dotdot2], 10);
        ty1 = try parseInt(i64, line[dotdot2 + 2 ..], 10);
    }

    // part 1: max height — best vy is -ty0 - 1 (arithmetic series)
    const best_vy = -ty0 - 1;
    const max_height = @divTrunc(best_vy * (best_vy + 1), 2);
    print("part 1: {d}\n", .{max_height});

    // part 2: count velocities that hit
    var count: u64 = 0;
    var vy: i64 = ty0;
    while (vy <= best_vy) : (vy += 1) {
        var vx: i64 = 1;
        while (vx <= tx1) : (vx += 1) {
            if (hits(vx, vy)) count += 1;
        }
    }
    print("part 2: {d}\n", .{count});
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
