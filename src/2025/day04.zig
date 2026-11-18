const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day04.txt");

const gw = 400;
const gh = 400;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var h: usize = 0;
var w: usize = 0;

fn accessibleNeighbors(x: usize, y: usize) u32 {
    var n: u32 = 0;
    for ([3]i32{ -1, 0, 1 }) |dy| {
        for ([3]i32{ -1, 0, 1 }) |dx| {
            if (dx == 0 and dy == 0) continue;
            const nx = @as(i64, @intCast(x)) + dx;
            const ny = @as(i64, @intCast(y)) + dy;
            if (nx < 0 or ny < 0 or nx >= w or ny >= h) continue;
            if (grid[@intCast(ny)][@intCast(nx)] == '@') n += 1;
        }
    }
    return n;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    // part 1: count accessible in the initial diagram
    var count: u64 = 0;
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == '@' and accessibleNeighbors(x, y) < 4) {
                count += 1;
            }
        }
    }
    print("part 1: {d}\n", .{count});

    // part 2: repeatedly remove all accessible rolls
    var removed: u64 = 0;
    while (true) {
        var to_remove: List([2]usize) = .empty;
        defer to_remove.deinit(gpa);
        for (0..h) |y| {
            for (0..w) |x| {
                if (grid[y][x] == '@' and accessibleNeighbors(x, y) < 4) {
                    to_remove.append(gpa, .{ x, y }) catch return;
                }
            }
        }
        if (to_remove.items.len == 0) break;
        removed += to_remove.items.len;
        for (to_remove.items) |c| {
            grid[c[1]][c[0]] = '.';
        }
    }
    print("part 2: {d}\n", .{removed});
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
