const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day13.txt");

var fav: u64 = 0; // parsed from the puzzle input
const target = [2]i32{ 31, 39 };
const max_xy = 60;

fn isOpen(x: i32, y: i32) bool {
    const n: u64 = @as(u64, @intCast(x * x + 3 * x + 2 * x * y + y + y * y)) + fav;
    return @popCount(n) % 2 == 0;
}

pub fn main() !void {
    fav = try parseInt(u64, trim(u8, data, " \n\r\t"), 10);

    var visited: [max_xy][max_xy]bool = @splat(@splat(false));

    var queue: List([3]i32) = .empty;
    defer queue.deinit(gpa);
    try queue.append(gpa, .{ 1, 1, 0 });
    visited[1][1] = true;

    var part1: i32 = -1;
    var within50: usize = 0;

    var qi: usize = 0;
    while (qi < queue.items.len) : (qi += 1) {
        const cur = queue.items[qi];
        const x = cur[0];
        const y = cur[1];
        const d = cur[2];

        if (d <= 50) within50 += 1;
        if (x == target[0] and y == target[1] and part1 == -1) part1 = d;

        const moves = [4][2]i32{ .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 }, .{ 0, -1 } };
        for (moves) |m| {
            const nx = x + m[0];
            const ny = y + m[1];
            if (nx < 0 or ny < 0 or nx >= max_xy or ny >= max_xy) continue;
            const ux: usize = @intCast(nx);
            const uy: usize = @intCast(ny);
            if (visited[uy][ux]) continue;
            if (!isOpen(nx, ny)) continue;
            visited[uy][ux] = true;
            try queue.append(gpa, .{ nx, ny, d + 1 });
        }
    }

    print("part 1: {d}\n", .{part1});
    print("part 2: {d}\n", .{within50});
}

// Useful stdlib functions
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
