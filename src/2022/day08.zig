const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day08.txt");

var grid: [200][200]u8 = @splat(@splat(0));
var h: usize = 0;
var w: usize = 0;

fn visible(x: usize, y: usize) bool {
    const v = grid[y][x];
    var up = true;
    var down = true;
    var left = true;
    var right = true;
    for (0..h) |yy| {
        if (yy < y and grid[yy][x] >= v) up = false;
        if (yy > y and grid[yy][x] >= v) down = false;
    }
    for (0..w) |xx| {
        if (xx < x and grid[y][xx] >= v) left = false;
        if (xx > x and grid[y][xx] >= v) right = false;
    }
    return up or down or left or right;
}

fn scenic(x: usize, y: usize) u64 {
    const v = grid[y][x];
    var up: u64 = 0;
    var yy = y;
    while (yy > 0) {
        yy -= 1;
        up += 1;
        if (grid[yy][x] >= v) break;
    }
    var down: u64 = 0;
    yy = y;
    while (yy + 1 < h) {
        yy += 1;
        down += 1;
        if (grid[yy][x] >= v) break;
    }
    var left: u64 = 0;
    var xx = x;
    while (xx > 0) {
        xx -= 1;
        left += 1;
        if (grid[y][xx] >= v) break;
    }
    var right: u64 = 0;
    xx = x;
    while (xx + 1 < w) {
        xx += 1;
        right += 1;
        if (grid[y][xx] >= v) break;
    }
    return up * down * left * right;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    var count: u32 = 0;
    var best: u64 = 0;
    for (0..h) |y| {
        for (0..w) |x| {
            if (visible(x, y)) count += 1;
            best = @max(best, scenic(x, y));
        }
    }
    print("part 1: {d}\n", .{count});
    print("part 2: {d}\n", .{best});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
