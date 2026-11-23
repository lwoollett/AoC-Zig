const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day04.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var h: usize = 0;
var w: usize = 0;

fn at(x: i64, y: i64) u8 {
    if (x < 0 or y < 0 or x >= w or y >= h) return '.';
    return grid[@intCast(y)][@intCast(x)];
}

fn countXmas(x: i64, y: i64) u32 {
    const dirs = [8][2]i64{
        .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 },  .{ 0, -1 },
        .{ 1, 1 }, .{ 1, -1 }, .{ -1, 1 }, .{ -1, -1 },
    };
    var count: u32 = 0;
    for (dirs) |d| {
        if (at(x + d[0], y + d[1]) == 'M' and
            at(x + 2 * d[0], y + 2 * d[1]) == 'A' and
            at(x + 3 * d[0], y + 3 * d[1]) == 'S')
        {
            count += 1;
        }
    }
    return count;
}

fn isXMas(x: i64, y: i64) bool {
    if (at(x, y) != 'A') return false;
    // two diagonal MAS/SAM pairs
    const d1 = [2][2]i64{ .{ -1, -1 }, .{ 1, 1 } };
    const d2 = [2][2]i64{ .{ -1, 1 }, .{ 1, -1 } };
    inline for (.{ d1, d2 }) |pair| {
        const a = at(x + pair[0][0], y + pair[0][1]);
        const b = at(x + pair[1][0], y + pair[1][1]);
        if (!((a == 'M' and b == 'S') or (a == 'S' and b == 'M'))) return false;
    }
    return true;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    var total1: u32 = 0;
    var total2: u32 = 0;
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == 'X') {
                total1 += countXmas(@intCast(x), @intCast(y));
            }
            if (isXMas(@intCast(x), @intCast(y))) {
                total2 += 1;
            }
        }
    }
    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{total2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
