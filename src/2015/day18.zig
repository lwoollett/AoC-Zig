const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day18.txt");

const n = 100;
const steps = 100;

var grid: [n][n]bool = @splat(@splat(false));

fn parse() void {
    var lines = splitSca(u8, data, '\n');
    var y: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        for (line, 0..) |c, x| {
            grid[y][x] = c == '#';
        }
        y += 1;
    }
}

fn neighborsOn(y: usize, x: usize) usize {
    var count: usize = 0;
    var dy: isize = -1;
    while (dy <= 1) : (dy += 1) {
        var dx: isize = -1;
        while (dx <= 1) : (dx += 1) {
            if (dy == 0 and dx == 0) continue;
            const yy = @as(isize, @intCast(y)) + dy;
            const xx = @as(isize, @intCast(x)) + dx;
            if (yy < 0 or xx < 0 or yy >= n or xx >= n) continue;
            if (grid[@intCast(yy)][@intCast(xx)]) count += 1;
        }
    }
    return count;
}

fn step(stuck_corners: bool) void {
    var next: [n][n]bool = @splat(@splat(false));
    for (0..n) |y| {
        for (0..n) |x| {
            const on = grid[y][x];
            const nb = neighborsOn(y, x);
            next[y][x] = if (on) (nb == 2 or nb == 3) else (nb == 3);
        }
    }
    grid = next;
    if (stuck_corners) {
        grid[0][0] = true;
        grid[0][n - 1] = true;
        grid[n - 1][0] = true;
        grid[n - 1][n - 1] = true;
    }
}

fn countOn() usize {
    var total: usize = 0;
    for (grid) |row| {
        for (row) |on| {
            if (on) total += 1;
        }
    }
    return total;
}

pub fn main() !void {
    // Part 1
    parse();
    for (0..steps) |_| step(false);
    print("part 1: {d}\n", .{countOn()});

    // Part 2: corners stuck on
    parse();
    grid[0][0] = true;
    grid[0][n - 1] = true;
    grid[n - 1][0] = true;
    grid[n - 1][n - 1] = true;
    for (0..steps) |_| step(true);
    print("part 2: {d}\n", .{countOn()});
}

// Useful stdlib functions
const splitSca = std.mem.splitScalar;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
