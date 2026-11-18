const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day16.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var h: usize = 0;
var w: usize = 0;

const Beam = struct { x: i64, y: i64, dx: i64, dy: i64 };

fn energized(sx: i64, sy: i64, sdx: i64, sdy: i64) !usize {
    var lit = try gpa.alloc([]bool, h);
    defer gpa.free(lit); // registered first -> runs last
    defer for (lit) |r| gpa.free(r);
    for (lit) |*r| {
        r.* = try gpa.alloc(bool, w);
        @memset(r.*, false);
    }

    var seen = Map([4]i64, void).init(gpa);
    defer seen.deinit();

    var q: List(Beam) = .empty;
    defer q.deinit(gpa);
    q.append(gpa, .{ .x = sx, .y = sy, .dx = sdx, .dy = sdy }) catch return 0;

    while (q.pop()) |b| {
        const nx = b.x + b.dx;
        const ny = b.y + b.dy;
        if (nx < 0 or ny < 0 or nx >= w or ny >= h) continue;
        const key = [4]i64{ nx, ny, b.dx, b.dy };
        if (seen.contains(key)) continue;
        try seen.put(key, {});
        lit[@intCast(ny)][@intCast(nx)] = true;

        const c = grid[@intCast(ny)][@intCast(nx)];
        switch (c) {
            '|' => {
                if (b.dx != 0) {
                    // split vertically
                    try q.append(gpa, .{ .x = nx, .y = ny, .dx = 0, .dy = -1 });
                    try q.append(gpa, .{ .x = nx, .y = ny, .dx = 0, .dy = 1 });
                    continue;
                }
            },
            '-' => {
                if (b.dy != 0) {
                    try q.append(gpa, .{ .x = nx, .y = ny, .dx = -1, .dy = 0 });
                    try q.append(gpa, .{ .x = nx, .y = ny, .dx = 1, .dy = 0 });
                    continue;
                }
            },
            '/' => {
                // reflect: (dx, dy) -> (-dy, -dx)
                try q.append(gpa, .{ .x = nx, .y = ny, .dx = -b.dy, .dy = -b.dx });
                continue;
            },
            '\\' => {
                // (dx, dy) -> (dy, dx)
                try q.append(gpa, .{ .x = nx, .y = ny, .dx = b.dy, .dy = b.dx });
                continue;
            },
            else => {},
        }
        try q.append(gpa, .{ .x = nx, .y = ny, .dx = b.dx, .dy = b.dy });
    }

    var count: usize = 0;
    for (lit) |r| {
        for (r) |v| {
            if (v) count += 1;
        }
    }
    return count;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    print("part 1: {d}\n", .{try energized(-1, 0, 1, 0)});

    var best: usize = 0;
    for (0..h) |y| {
        best = @max(best, try energized(-1, @intCast(y), 1, 0));
        best = @max(best, try energized(@intCast(w), @intCast(y), -1, 0));
    }
    for (0..w) |x| {
        best = @max(best, try energized(@intCast(x), -1, 0, 1));
        best = @max(best, try energized(@intCast(x), @intCast(h), 0, -1));
    }
    print("part 2: {d}\n", .{best});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.findScalar;
const indexOfAny = std.mem.findAny;
const indexOfStr = std.mem.findPos;
const lastIndexOf = std.mem.findScalarLast;
const lastIndexOfAny = std.mem.findLastAny;
const lastIndexOfStr = std.mem.findLastLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be modified.
