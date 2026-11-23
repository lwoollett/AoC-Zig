const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day11.txt");

const gw = 12;
const gh = 12;
var grid: [gh][gw]u8 = @splat(@splat('0'));

fn flashRound() usize {
    var flashed: [gh][gw]bool = @splat(@splat(false));
    // energy up
    for (1..gh - 1) |y| {
        for (1..gw - 1) |x| {
            grid[y][x] += 1;
        }
    }
    var total: usize = 0;
    var changed = true;
    while (changed) {
        changed = false;
        for (1..gh - 1) |y| {
            for (1..gw - 1) |x| {
                if (grid[y][x] > '9' and !flashed[y][x]) {
                    flashed[y][x] = true;
                    total += 1;
                    changed = true;
                    for ([3]i32{ -1, 0, 1 }) |dy| {
                        for ([3]i32{ -1, 0, 1 }) |dx| {
                            if (dx == 0 and dy == 0) continue;
                            const ny = @as(i32, @intCast(y)) + dy;
                            const nx = @as(i32, @intCast(x)) + dx;
                            if (ny < 1 or nx < 1 or ny >= gh - 1 or nx >= gw - 1) continue;
                            grid[@intCast(ny)][@intCast(nx)] += 1;
                        }
                    }
                }
            }
        }
    }
    // reset
    for (1..gh - 1) |y| {
        for (1..gw - 1) |x| {
            if (flashed[y][x]) grid[y][x] = '0';
        }
    }
    return total;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    var row: usize = 1;
    while (lines.next()) |line| {
        @memcpy(grid[row][1 .. 1 + line.len], line);
        row += 1;
    }

    var step: usize = 0;
    var total_flashes: usize = 0;
    var first_sync: ?usize = null;
    while (step < 1000) : (step += 1) {
        const n = flashRound();
        if (step < 100) total_flashes += n;
        if (n == 100 and first_sync == null) {
            first_sync = step + 1;
        }
    }
    print("part 1: {d}\n", .{total_flashes});
    print("part 2: {d}\n", .{first_sync.?});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
