const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day07.txt");

const gw = 800;
const gh = 4000;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var h: usize = 0;
var w: usize = 0;

const Cell = [2]i64;

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    // find S
    var sx: i64 = 0;
    for (0..w) |x| {
        if (grid[0][x] == 'S') sx = @intCast(x);
    }

    // BFS: beam at (x, y): if splitter -> emit (x-1, y), (x+1, y); else (x, y+1)
    var visited = Map(Cell, void).init(gpa);
    defer visited.deinit();
    var q: List(Cell) = .empty;
    defer q.deinit(gpa);
    try visited.put(.{ sx, 0 }, {});
    try q.append(gpa, .{ sx, 0 });

    var splits: u64 = 0;
    var head: usize = 0;
    while (head < q.items.len) : (head += 1) {
        const cur = q.items[head];
        const x = cur[0];
        const y = cur[1];
        if (x < 0 or x >= w or y < 0 or y >= h) continue;
        const c = grid[@intCast(y)][@intCast(x)];
        if (c == '^') {
            splits += 1;
            for ([2]i64{ x - 1, x + 1 }) |nx| {
                const nc = Cell{ nx, y };
                if (!visited.contains(nc)) {
                    try visited.put(nc, {});
                    try q.append(gpa, nc);
                }
            }
        } else {
            const nc = Cell{ x, y + 1 };
            if (!visited.contains(nc)) {
                try visited.put(nc, {});
                try q.append(gpa, nc);
            }
        }
    }
    print("part 1: {d}\n", .{splits});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
