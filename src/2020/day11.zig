const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day11.txt");

const gw = 128;
const gh = 128;

var grid: [gh][gw]u8 = @splat(@splat('.'));
var w: usize = 0;
var h: usize = 0;

fn occupiedAdjacent(x: usize, y: usize) u32 {
    var count: u32 = 0;
    for ([3]i32{ -1, 0, 1 }) |dy| {
        for ([3]i32{ -1, 0, 1 }) |dx| {
            if (dx == 0 and dy == 0) continue;
            const nx = @as(i32, @intCast(x)) + dx;
            const ny = @as(i32, @intCast(y)) + dy;
            if (nx < 0 or ny < 0 or nx >= gw or ny >= gh) continue;
            if (grid[@intCast(ny)][@intCast(nx)] == '#') count += 1;
        }
    }
    return count;
}

fn occupiedVisible(x: usize, y: usize) u32 {
    var count: u32 = 0;
    const dirs = [8][2]i32{ .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 }, .{ -1, 0 }, .{ 1, 0 }, .{ -1, 1 }, .{ 0, 1 }, .{ 1, 1 } };
    for (dirs) |d| {
        var cx: i64 = @intCast(x);
        var cy: i64 = @intCast(y);
        while (true) {
            cx += d[0];
            cy += d[1];
            if (cx < 0 or cy < 0 or cx >= gw or cy >= gh) break;
            const c = grid[@intCast(cy)][@intCast(cx)];
            if (c == '#') {
                count += 1;
                break;
            }
            if (c == 'L') break;
        }
    }
    return count;
}

fn step(comptime visible: bool, comptime limit: u32) bool {
    var next: [gh][gw]u8 = @splat(@splat('.'));
    var changed = false;
    for (0..h) |y| {
        for (0..w) |x| {
            const c = grid[y][x];
            if (c == '.') continue;
            const occ = if (visible) occupiedVisible(x, y) else occupiedAdjacent(x, y);
            if (c == 'L' and occ == 0) {
                next[y][x] = '#';
                changed = true;
            } else if (c == '#' and occ >= limit) {
                next[y][x] = 'L';
                changed = true;
            } else {
                next[y][x] = c;
            }
        }
    }
    grid = next;
    return changed;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    // part 1
    while (step(false, 4)) {}
    var total: u32 = 0;
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == '#') total += 1;
        }
    }
    print("part 1: {d}\n", .{total});

    // reset and part 2
    {
        var l2 = tokenizeAny(u8, data, "\n");
        h = 0;
        w = 0;
        while (l2.next()) |line| {
            if (line.len == 0) continue;
            @memcpy(grid[h][0..line.len], line);
            w = @max(w, line.len);
            h += 1;
        }
    }
    while (step(true, 5)) {}
    total = 0;
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == '#') total += 1;
        }
    }
    print("part 2: {d}\n", .{total});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
