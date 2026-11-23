const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day03.txt");

const size = 1000;
// 0 = unclaimed, -1 = contested, >0 = claim id
var grid: [size][size]i32 = @splat(@splat(0));

pub fn main() !void {
    var n_claims: i32 = 0;
    var contested: u64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // #1 @ 1,3: 4x4
        var it = tokenizeAny(u8, line, "#@,:x ");
        _ = it.next().?; // id (track separately)
        n_claims += 1;
        const id = n_claims;
        const x = try parseInt(usize, it.next().?, 10);
        const y = try parseInt(usize, it.next().?, 10);
        const w = try parseInt(usize, it.next().?, 10);
        const h = try parseInt(usize, it.next().?, 10);

        for (0..h) |dy| {
            for (0..w) |dx| {
                const gy = y + dy;
                const gx = x + dx;
                if (gy >= size or gx >= size) continue;
                if (grid[gy][gx] == 0) {
                    grid[gy][gx] = id;
                } else {
                    grid[gy][gx] = -1;
                }
            }
        }
    }

    for (grid) |row| {
        for (row) |cell| {
            if (cell == -1) contested += 1;
        }
    }
    print("part 1: {d}\n", .{contested});

    // part 2: re-apply each claim; the one that never touches a contested cell
    lines = tokenizeAny(u8, data, "\n");
    var id: i32 = 0;
    while (lines.next()) |line| {
        id += 1;
        var it = tokenizeAny(u8, line, "#@,:x ");
        _ = it.next().?;
        const x = try parseInt(usize, it.next().?, 10);
        const y = try parseInt(usize, it.next().?, 10);
        const w = try parseInt(usize, it.next().?, 10);
        const h = try parseInt(usize, it.next().?, 10);
        var clean = true;
        outer: for (0..h) |dy| {
            for (0..w) |dx| {
                const gy = y + dy;
                const gx = x + dx;
                if (gy >= size or gx >= size) continue;
                if (grid[gy][gx] == -1 or grid[gy][gx] != id) {
                    clean = false;
                    break :outer;
                }
            }
        }
        if (clean) {
            print("part 2: {d}\n", .{id});
            return;
        }
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
