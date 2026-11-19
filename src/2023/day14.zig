const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day14.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var h: usize = 0;
var w: usize = 0;

fn tiltNorth() void {
    for (0..w) |x| {
        var write_y: usize = 0;
        for (0..h) |y| {
            const c = grid[y][x];
            if (c == 'O') {
                grid[y][x] = '.';
                grid[write_y][x] = 'O';
                write_y += 1;
            } else if (c == '#') {
                write_y = y + 1;
            }
        }
    }
}

fn tiltWest() void {
    for (0..h) |y| {
        var write_x: usize = 0;
        for (0..w) |x| {
            const c = grid[y][x];
            if (c == 'O') {
                grid[y][x] = '.';
                grid[y][write_x] = 'O';
                write_x += 1;
            } else if (c == '#') {
                write_x = x + 1;
            }
        }
    }
}

fn tiltSouth() void {
    for (0..w) |x| {
        var write_y: usize = h - 1;
        var y: usize = h;
        while (y > 0) {
            y -= 1;
            const c = grid[y][x];
            if (c == 'O') {
                grid[y][x] = '.';
                grid[write_y][x] = 'O';
                if (write_y == 0) break;
                write_y -= 1;
            } else if (c == '#') {
                if (y == 0) break;
                write_y = y - 1;
            }
        }
    }
}

fn tiltEast() void {
    for (0..h) |y| {
        var write_x: usize = w - 1;
        var x: usize = w;
        while (x > 0) {
            x -= 1;
            const c = grid[y][x];
            if (c == 'O') {
                grid[y][x] = '.';
                grid[y][write_x] = 'O';
                if (write_x == 0) break;
                write_x -= 1;
            } else if (c == '#') {
                if (x == 0) break;
                write_x = x - 1;
            }
        }
    }
}

fn northLoad() u64 {
    var load: u64 = 0;
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == 'O') {
                load += h - y;
            }
        }
    }
    return load;
}

fn cycle() void {
    tiltNorth();
    tiltWest();
    tiltSouth();
    tiltEast();
}

fn gridKey() u64 {
    var hash = std.hash.Wyhash.init(0);
    for (0..h) |y| {
        hash.update(grid[y][0..w]);
    }
    return hash.final();
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    tiltNorth();
    print("part 1: {d}\n", .{northLoad()});

    // reset for part 2 (tilt once more southward to undo part 1's tilt)
    // simplest: re-parse
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

    var seen = Map(u64, u64).init(gpa);
    defer seen.deinit();
    var cycle_start: u64 = 0;
    var cycle_len: u64 = 0;
    var iter: u64 = 0;
    while (iter < 1_000_000_000) : (iter += 1) {
        cycle();
        const key = gridKey();
        if (seen.get(key)) |first| {
            cycle_start = first;
            cycle_len = iter - first;
            break;
        }
        try seen.put(key, iter);
    }
    if (cycle_len > 0) {
        const remaining = (1_000_000_000 - cycle_start) % cycle_len;
        for (0..remaining) |_| {
            cycle();
        }
    } else {
        for (iter..1_000_000_000) |_| {
            cycle();
        }
    }
    print("part 2: {d}\n", .{northLoad()});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
