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

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var w: usize = 0;
var h: usize = 0;

fn stepEast() bool {
    var next = grid;
    var moved = false;
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == '>') {
                const nx = (x + 1) % w;
                if (grid[y][nx] == '.') {
                    next[y][nx] = '>';
                    next[y][x] = '.';
                    moved = true;
                }
            }
        }
    }
    grid = next;
    return moved;
}

fn stepSouth() bool {
    var next = grid;
    var moved = false;
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == 'v') {
                const ny = (y + 1) % h;
                if (grid[ny][x] == '.') {
                    next[ny][x] = 'v';
                    next[y][x] = '.';
                    moved = true;
                }
            }
        }
    }
    grid = next;
    return moved;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    var step_count: u32 = 0;
    while (true) {
        step_count += 1;
        const m1 = stepEast();
        const m2 = stepSouth();
        if (!m1 and !m2) {
            print("part 1: {d}\n", .{step_count});
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
// Only unmodified days will be modified.
