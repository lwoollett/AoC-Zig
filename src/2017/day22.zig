const std = @import("std");
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day22.txt");

// The virus wanders at most ~sqrt(bursts) cells from the origin in practice;
// a fixed offset grid (with a guard) beats a hashmap on every access.
const R: i64 = 4000;
const side: usize = @intCast(2 * R + 1);

pub fn main() !void {
    // Parse initial infected cells from the input grid.
    var initial: [512][512]u8 = @splat(@splat(0));
    var w: usize = 0;
    var h: usize = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        w = @max(w, line.len);
        for (line, 0..) |c, x| {
            initial[h][x] = if (c == '#') 1 else 0;
        }
        h += 1;
    }

    const grid = try gpa.alloc(u8, side * side);
    defer gpa.free(grid);
    @memset(grid, 0); // page_allocator hands back dirty pages — always zero

    // world coords: input (x,y) centered at (w/2, h/2)
    for (0..h) |y| {
        for (0..w) |x| {
            if (initial[y][x] == 1) {
                const wy: i64 = @as(i64, @intCast(y)) - @as(i64, @intCast(h / 2));
                const wx: i64 = @as(i64, @intCast(x)) - @as(i64, @intCast(w / 2));
                grid[@intCast((wy + R) * side + (wx + R))] = 1;
            }
        }
    }

    // Part 1: 2-state, 10000 bursts.
    {
        var x: i64 = 0;
        var y: i64 = 0;
        var dx: i64 = 0;
        var dy: i64 = -1;
        var infected: u32 = 0;
        var bursts: u32 = 0;
        while (bursts < 10_000) : (bursts += 1) {
            const i: usize = @intCast((y + R) * side + (x + R));
            if (grid[i] == 1) {
                // turn right
                const t = dx;
                dx = -dy;
                dy = t;
            } else {
                // turn left
                const t = dx;
                dx = dy;
                dy = -t;
            }
            grid[i] = 1 - grid[i];
            if (grid[i] == 1) infected += 1;
            x += dx;
            y += dy;
        }
        print("part 1: {d}\n", .{infected});
    }

    // Part 2: 4-state, 10M bursts. (0 clean, 1 weakened, 2 infected, 3 flagged)
    {
        @memset(grid, 0);
        for (0..h) |y| {
            for (0..w) |x| {
                if (initial[y][x] == 1) {
                    const wy: i64 = @as(i64, @intCast(y)) - @as(i64, @intCast(h / 2));
                    const wx: i64 = @as(i64, @intCast(x)) - @as(i64, @intCast(w / 2));
                    grid[@intCast((wy + R) * side + (wx + R))] = 2;
                }
            }
        }
        var x: i64 = 0;
        var y: i64 = 0;
        var dx: i64 = 0;
        var dy: i64 = -1;
        var infected: u32 = 0;
        var bursts: u32 = 0;
        while (bursts < 10_000_000) : (bursts += 1) {
            const i: usize = @intCast((y + R) * side + (x + R));
            switch (grid[i]) {
                0 => { // clean: turn left
                    const t = dx;
                    dx = dy;
                    dy = -t;
                },
                1 => {}, // weakened: no turn
                2 => { // infected: turn right
                    const t = dx;
                    dx = -dy;
                    dy = t;
                },
                else => { // flagged: reverse
                    dx = -dx;
                    dy = -dy;
                },
            }
            grid[i] = (grid[i] + 1) % 4;
            if (grid[i] == 2) infected += 1;
            x += dx;
            y += dy;
            if (x < -R or x > R or y < -R or y > R) return error.OutOfBounds;
        }
        print("part 2: {d}\n", .{infected});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
