const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day10.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var h: usize = 0;
var w: usize = 0;

/// Does the pipe at (x,y) connect in direction d? (0=R,1=D,2=L,3=U)
fn connects(x: usize, y: usize, d: u8) bool {
    if (x >= w or y >= h) return false;
    const c = grid[y][x];
    if (c == '.') return false;
    // directions: 0=R, 1=D, 2=L, 3=U
    const dl = switch (c) {
        '|' => [_]bool{ false, true, false, true },
        '-' => [_]bool{ true, false, true, false },
        'L' => [_]bool{ true, false, false, true }, // R+U
        'J' => [_]bool{ false, false, true, true }, // L+U
        '7' => [_]bool{ false, true, true, false }, // L+D
        'F' => [_]bool{ true, true, false, false }, // R+D
        'S' => [_]bool{ true, true, true, true }, // replaced later
        else => [_]bool{ false, false, false, false },
    };
    return dl[d];
}

const dx = [4]i32{ 1, 0, -1, 0 };
const dy = [4]i32{ 0, 1, 0, -1 };
const opposite = [4]u8{ 2, 3, 0, 1 };

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    // find S
    var sx: usize = 0;
    var sy: usize = 0;
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == 'S') {
                sx = x;
                sy = y;
            }
        }
    }

    // determine S's pipe shape from neighbors
    const conn_r = connects(sx + 1, sy, 2);
    const conn_d = connects(sx, sy + 1, 3);
    var conn_l = false;
    var conn_u = false;
    if (sx > 0) conn_l = connects(sx - 1, sy, 0);
    if (sy > 0) conn_u = connects(sx, sy - 1, 1);
    const s_pipe: u8 = blk: {
        if (conn_r and conn_d) break :blk 'F';
        if (conn_r and conn_u) break :blk 'L';
        if (conn_l and conn_d) break :blk '7';
        if (conn_l and conn_u) break :blk 'J';
        if (conn_l and conn_r) break :blk '-';
        break :blk '|';
    };
    grid[sy][sx] = s_pipe;

    // walk the loop from S in direction R (or first connected)
    var in_loop = try gpa.alloc(bool, w * h);
    defer gpa.free(in_loop);
    @memset(in_loop, false);

    var start_dir: u8 = 0;
    for (0..4) |d| {
        if (connects(sx, sy, @intCast(d))) {
            start_dir = @intCast(d);
            break;
        }
    }

    var cx: usize = sx;
    var cy: usize = sy;
    var dir: u8 = start_dir;
    var length: usize = 0;
    while (true) {
        in_loop[cy * w + cx] = true;
        // step in dir
        const nx = @as(i32, @intCast(cx)) + dx[dir];
        const ny = @as(i32, @intCast(cy)) + dy[dir];
        cx = @intCast(nx);
        cy = @intCast(ny);
        length += 1;
        if (cx == sx and cy == sy) break;
        // continue through the pipe: enter from opposite[dir], exit the other side
        var nd: u8 = 0;
        for (0..4) |d2| {
            if (d2 == opposite[dir]) continue;
            if (connects(cx, cy, @intCast(d2))) {
                nd = @intCast(d2);
                break;
            }
        }
        dir = nd;
    }
    print("part 1: {d}\n", .{length / 2});

    // part 2: count cells inside the loop (ray casting per row)
    var inside: u64 = 0;
    for (0..h) |y| {
        var crossings: u32 = 0;
        var prev_corner: u8 = 0;
        for (0..w) |x| {
            if (in_loop[y * w + x]) {
                const c = grid[y][x];
                if (c == '|') {
                    crossings += 1;
                } else if (c == 'F' or c == 'L') {
                    prev_corner = c;
                } else if (c == 'J') {
                    if (prev_corner == 'F') crossings += 1;
                    prev_corner = 0;
                } else if (c == '7') {
                    if (prev_corner == 'L') crossings += 1;
                    prev_corner = 0;
                }
                // '-' contributes nothing
            } else {
                if (crossings % 2 == 1) inside += 1;
            }
        }
    }
    print("part 2: {d}\n", .{inside});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
