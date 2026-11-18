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

const gw = 1100;
const gh = 220;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var max_y: usize = 0;

fn drawSeg(x1: i64, y1: i64, x2: i64, y2: i64) void {
    if (x1 == x2) {
        var y = @min(y1, y2);
        while (y <= @max(y1, y2)) : (y += 1) {
            grid[@intCast(y)][@intCast(x1 + 400)] = '#';
        }
    } else {
        var x = @min(x1, x2);
        while (x <= @max(x1, x2)) : (x += 1) {
            grid[@intCast(y1)][@intCast(x + 400)] = '#';
        }
    }
}

fn dropSand(floor_y: usize) bool {
    var x: usize = 400 + 500;
    var y: usize = 0;
    if (grid[0][x] != '.') return false;
    while (true) {
        if (y + 1 >= gh) return false;
        if (y + 1 == floor_y) {
            grid[y][x] = 'o';
            return true;
        }
        if (grid[y + 1][x] == '.') {
            y += 1;
        } else if (x > 0 and grid[y + 1][x - 1] == '.') {
            y += 1;
            x -= 1;
        } else if (x + 1 < gw and grid[y + 1][x + 1] == '.') {
            y += 1;
            x += 1;
        } else {
            grid[y][x] = 'o';
            return true;
        }
        if (y > max_y + 3) return false; // into the void (part 1)
    }
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeSca(u8, line, '>');
        var prev: ?[2]i64 = null;
        while (it.next()) |pt_raw| {
            const pt = trim(u8, pt_raw, " -");
            const comma = indexOf(u8, pt, ',').?;
            const x = try parseInt(i64, pt[0..comma], 10);
            const y = try parseInt(i64, pt[comma + 1 ..], 10);
            max_y = @max(max_y, @as(usize, @intCast(y)));
            if (prev) |p| {
                drawSeg(p[0], p[1], x, y);
            }
            prev = .{ x, y };
        }
    }

    // part 1: void below
    var count: u32 = 0;
    while (dropSand(std.math.maxInt(usize))) {
        count += 1;
    }
    print("part 1: {d}\n", .{count});

    // part 2: floor at max_y + 2; reset sand
    for (&grid) |*row| {
        for (row) |*c| {
            if (c.* == 'o') c.* = '.';
        }
    }
    count = 0;
    while (dropSand(max_y + 2)) {
        count += 1;
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
// Only unmodified days will be modified.
