const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day15.txt");

const gw = 300;
const gh = 300;
var grid: [gh][gw]u8 = @splat(@splat('#'));
var w: usize = 0;
var h: usize = 0;
var moves: List(u8) = .empty;

fn tryMoveWide(x: usize, y: usize, dx: i64, dy: i64) bool {
    // wide-box warehouse move: try to push whatever is at (x,y)
    const c = grid[y][x];
    if (c == '.') return true;
    if (c == '#') return false;
    // box left/right halves
    const nx = @as(i64, @intCast(x)) + dx;
    const ny = @as(i64, @intCast(y)) + dy;
    if (nx < 0 or ny < 0 or nx >= w or ny >= h) return false;
    if (dy == 0) {
        // horizontal: chain through the same row
        if (!tryMoveWide(@intCast(nx), y, dx, dy)) return false;
        grid[y][x] = '.';
        grid[@intCast(nx)][x] = c;
        return true;
    }
    // vertical: box occupies two columns
    const bx: usize = if (c == '[') x else x - 1;
    const bx2 = bx + 1;
    if (!tryMoveWide(bx, @intCast(ny), dx, dy)) return false;
    if (!tryMoveWide(bx2, @intCast(ny), dx, dy)) return false;
    grid[y][bx] = '.';
    grid[y][bx2] = '.';
    grid[@intCast(ny)][bx] = '[';
    grid[@intCast(ny)][bx2] = ']';
    return true;
}

fn gpsSum() u64 {
    var total: u64 = 0;
    for (0..h) |y| {
        for (0..w) |x| {
            // part 1: 'O'; part 2: '[' (left half)
            if (grid[y][x] == 'O' or grid[y][x] == '[') {
                total += 100 * y + x;
            }
        }
    }
    return total;
}

pub fn main() !void {
    // parse grid + moves
    var rx: usize = 0;
    var ry: usize = 0;
    {
        var lines = splitSca(u8, data, '\n');
        var in_moves = false;
        while (lines.next()) |line_raw| {
            const line = trim(u8, line_raw, " \r");
            if (line.len == 0) {
                in_moves = true;
                continue;
            }
            if (!in_moves) {
                @memcpy(grid[h][0..line.len], line);
                for (line, 0..) |c, x| {
                    if (c == '@') {
                        rx = x;
                        ry = h;
                    }
                }
                w = @max(w, line.len);
                h += 1;
            } else {
                for (line) |c| {
                    if (c != ' ') try moves.append(gpa, c);
                }
            }
        }
    }

    // part 1: narrow boxes
    {
        for (moves.items) |m| {
            const d: [2]i64 = switch (m) {
                '^' => .{ 0, -1 },
                'v' => .{ 0, 1 },
                '<' => .{ -1, 0 },
                else => .{ 1, 0 },
            };
            // find the chain
            var chain: usize = 1;
            while (true) {
                const nx = @as(i64, @intCast(rx)) + @as(i64, @intCast(chain)) * d[0];
                const ny = @as(i64, @intCast(ry)) + @as(i64, @intCast(chain)) * d[1];
                const c = grid[@intCast(ny)][@intCast(nx)];
                if (c == '.') break;
                if (c == '#') {
                    chain = 0;
                    break;
                }
                chain += 1;
            }
            if (chain == 0) continue;
            // push the chain
            var k = chain;
            while (k > 0) : (k -= 1) {
                const nx = @as(i64, @intCast(rx)) + @as(i64, @intCast(k)) * d[0];
                const ny = @as(i64, @intCast(ry)) + @as(i64, @intCast(k)) * d[1];
                grid[@intCast(ny)][@intCast(nx)] = grid[@intCast(ny - d[1])][@intCast(nx - d[0])];
            }
            grid[ry][rx] = '.';
            rx = @intCast(@as(i64, @intCast(rx)) + d[0]);
            ry = @intCast(@as(i64, @intCast(ry)) + d[1]);
            grid[ry][rx] = '@';
        }
        print("part 1: {d}\n", .{gpsSum()});
    }

    // part 2: wide warehouse — rebuild the grid doubled horizontally
    {
        var wide: [gh][gw]u8 = @splat(@splat('#'));
        // NOTE: part 1 mutated grid — re-parse from data
        var l2 = splitSca(u8, data, '\n');
        var hh: usize = 0;
        var ww: usize = 0;
        var rrx: usize = 0;
        var rry: usize = 0;
        var in_moves2 = false;
        while (l2.next()) |line_raw| {
            const line = trim(u8, line_raw, " \r");
            if (line.len == 0) {
                in_moves2 = true;
                continue;
            }
            if (in_moves2) continue;
            for (line, 0..) |c, x| {
                const dx = x * 2;
                switch (c) {
                    '#' => {
                        wide[hh][dx] = '#';
                        wide[hh][dx + 1] = '#';
                    },
                    'O' => {
                        wide[hh][dx] = '[';
                        wide[hh][dx + 1] = ']';
                    },
                    '@' => {
                        wide[hh][dx] = '@';
                        wide[hh][dx + 1] = '.';
                        rrx = dx;
                        rry = hh;
                    },
                    else => {
                        wide[hh][dx] = '.';
                        wide[hh][dx + 1] = '.';
                    },
                }
            }
            ww = @max(ww, line.len * 2);
            hh += 1;
        }
        grid = wide;
        w = ww;
        h = hh;

        for (moves.items) |m| {
            const d: [2]i64 = switch (m) {
                '^' => .{ 0, -1 },
                'v' => .{ 0, 1 },
                '<' => .{ -1, 0 },
                else => .{ 1, 0 },
            };
            const nx = @as(i64, @intCast(rrx)) + d[0];
            const ny = @as(i64, @intCast(rry)) + d[1];
            if (nx < 0 or ny < 0 or nx >= w or ny >= h) continue;
            if (grid[@intCast(ny)][@intCast(nx)] == '#') continue;
            if (grid[@intCast(ny)][@intCast(nx)] == '.' or tryMoveWide(@intCast(nx), @intCast(ny), d[0], d[1])) {
                grid[rry][rrx] = '.';
                rrx = @intCast(nx);
                rry = @intCast(ny);
                grid[rry][rrx] = '@';
            }
        }
        print("part 2: {d}\n", .{gpsSum()});
    }
}

// Useful stdlib functions
const splitSca = std.mem.splitScalar;
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
