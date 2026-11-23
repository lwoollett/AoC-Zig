const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day19.txt");

const gw = 220;
const gh = 220;
var grid: [gh][gw]u8 = @splat(@splat(' '));
var w: usize = 0;
var h: usize = 0;

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    // start at the only | in row 0
    var x: usize = 0;
    while (x < w and grid[0][x] != '|') x += 1;
    var y: usize = 0;
    var dx: i8 = 0;
    var dy: i8 = 1;

    var letters: [64]u8 = undefined;
    var n_letters: usize = 0;
    var steps: u64 = 0;

    while (true) {
        steps += 1;
        const nx = @as(isize, @intCast(x)) + dx;
        const ny = @as(isize, @intCast(y)) + dy;
        if (nx < 0 or ny < 0) break;
        x = @intCast(nx);
        y = @intCast(ny);
        if (y >= gh or x >= gw) break;
        const c = grid[y][x];
        if (c == ' ') break;
        if (c >= 'A' and c <= 'Z') {
            letters[n_letters] = c;
            n_letters += 1;
        }
        if (c == '+') {
            // turn: try perpendicular directions
            if (dx == 0) {
                // was moving vertically; go left or right
                dx = if (x > 0 and grid[y][x - 1] != ' ') -1 else 1;
                dy = 0;
            } else {
                dy = if (y > 0 and grid[y - 1][x] != ' ') -1 else 1;
                dx = 0;
            }
        }
    }

    print("part 1: {s}\n", .{letters[0..n_letters]});
    print("part 2: {d}\n", .{steps});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
