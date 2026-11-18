const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day03.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var h: usize = 0;
var w: usize = 0;

fn isSymbol(c: u8) bool {
    return c != '.' and (c < '0' or c > '9');
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    var total1: u64 = 0;
    var total2: u64 = 0;

    // per row: numbers with (value, start, end); adjacency to symbols
    for (0..h) |y| {
        var x: usize = 0;
        while (x < w) {
            if (grid[y][x] < '0' or grid[y][x] > '9') {
                x += 1;
                continue;
            }
            const start = x;
            var v: u64 = 0;
            while (x < w and grid[y][x] >= '0' and grid[y][x] <= '9') {
                v = v * 10 + (grid[y][x] - '0');
                x += 1;
            }
            // adjacent symbol?
            var has_symbol = false;
            var yy: i64 = @as(i64, @intCast(y)) - 1;
            while (yy <= @as(i64, @intCast(y)) + 1) : (yy += 1) {
                var xx: i64 = @as(i64, @intCast(start)) - 1;
                while (xx <= @as(i64, @intCast(x))) : (xx += 1) {
                    if (yy < 0 or xx < 0 or yy >= h or xx >= w) continue;
                    const c = grid[@intCast(yy)][@intCast(xx)];
                    if (isSymbol(c)) has_symbol = true;
                }
            }
            if (has_symbol) total1 += v;
        }
    }

    // part 2: gears (*) adjacent to exactly two numbers
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] != '*') continue;
            // find adjacent numbers
            var nums: List(u64) = .empty;
            defer nums.deinit(gpa);
            var yy: i64 = @as(i64, @intCast(y)) - 1;
            while (yy <= @as(i64, @intCast(y)) + 1) : (yy += 1) {
                if (yy < 0 or yy >= h) continue;
                // scan the row for numbers touching column x
                var xx: usize = 0;
                while (xx < w) {
                    if (grid[@intCast(yy)][xx] < '0' or grid[@intCast(yy)][xx] > '9') {
                        xx += 1;
                        continue;
                    }
                    const start = xx;
                    var v: u64 = 0;
                    while (xx < w and grid[@intCast(yy)][xx] >= '0' and grid[@intCast(yy)][xx] <= '9') {
                        v = v * 10 + (grid[@intCast(yy)][xx] - '0');
                        xx += 1;
                    }
                    // does [start, xx) touch x?
                    const touch = @as(i64, @intCast(start)) <= @as(i64, @intCast(x)) + 1 and
                        @as(i64, @intCast(xx)) >= @as(i64, @intCast(x));
                    if (touch) {
                        try nums.append(gpa, v);
                    }
                }
            }
            if (nums.items.len == 2) {
                total2 += nums.items[0] * nums.items[1];
            }
        }
    }

    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{total2});
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
