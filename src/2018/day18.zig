const std = @import("std");
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day18.txt");

const n = 50;

var grid: [n][n]u8 = @splat(@splat('.'));
var next: [n][n]u8 = @splat(@splat('.'));

fn adjCount(y: usize, x: usize) [3]u32 {
    var counts = [3]u32{ 0, 0, 0 }; // ., |, #
    var dy: isize = -1;
    while (dy <= 1) : (dy += 1) {
        var dx: isize = -1;
        while (dx <= 1) : (dx += 1) {
            if (dy == 0 and dx == 0) continue;
            const yy = @as(isize, @intCast(y)) + dy;
            const xx = @as(isize, @intCast(x)) + dx;
            if (yy < 0 or xx < 0 or yy >= n or xx >= n) continue;
            switch (grid[@intCast(yy)][@intCast(xx)]) {
                '.' => counts[0] += 1,
                '|' => counts[1] += 1,
                '#' => counts[2] += 1,
                else => {},
            }
        }
    }
    return counts;
}

fn step() void {
    for (0..n) |y| {
        for (0..n) |x| {
            const c = grid[y][x];
            const adj = adjCount(y, x);
            next[y][x] = switch (c) {
                '.' => if (adj[1] >= 3) '|' else '.',
                '|' => if (adj[2] >= 3) '#' else '|',
                else => if (adj[2] >= 1 and adj[1] >= 1) '#' else '.',
            };
        }
    }
    for (0..n) |y| {
        for (0..n) |x| {
            grid[y][x] = next[y][x];
        }
    }
}

fn score() u64 {
    var wood: u64 = 0;
    var yards: u64 = 0;
    for (grid) |row| {
        for (row) |c| {
            if (c == '|') wood += 1;
            if (c == '#') yards += 1;
        }
    }
    return wood * yards;
}

fn key() ![]u8 {
    var buf = try gpa.alloc(u8, n * n);
    for (0..n) |y| {
        @memcpy(buf[y * n .. (y + 1) * n], &grid[y]);
    }
    return buf;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    var y: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(&grid[y], line[0..n]);
        y += 1;
    }

    var minute: u64 = 0;
    while (minute < 10) : (minute += 1) step();
    print("part 1: {d}\n", .{score()});

    // part 2: cycle detection
    var seen = StrMap(u64).init(gpa);
    defer {
        var kit = seen.keyIterator();
        while (kit.next()) |k| gpa.free(k.*);
        seen.deinit();
    }
    while (minute < 1_000_000_000) : (minute += 1) {
        const k = try key();
        if (seen.get(k)) |first| {
            const cycle = minute - first;
            const remaining = (1_000_000_000 - minute) % cycle;
            var r: u64 = 0;
            while (r < remaining) : (r += 1) step();
            print("part 2: {d}\n", .{score()});
            return;
        }
        try seen.put(k, minute);
        step();
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
