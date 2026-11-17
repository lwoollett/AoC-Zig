const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day22.txt");

// cell states for part 2: 0 clean, 1 weakened, 2 infected, 3 flagged
const V = struct {
    grid: Map([2]i64, u8),

    fn get(self: *V, x: i64, y: i64) u8 {
        return self.grid.get(.{ x, y }) orelse 0;
    }
    fn put(self: *V, x: i64, y: i64, v: u8) !void {
        try self.grid.put(.{ x, y }, v);
    }
};

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

    // Part 1: 2-state, 10000 bursts.
    {
        var grid = Map([2]i64, u8).init(gpa);
        defer grid.deinit();
        var v = V{ .grid = grid };
        for (0..h) |y| {
            for (0..w) |x| {
                if (initial[y][x] == 1) {
                    try v.put(@as(i64, @intCast(x)) - @as(i64, @intCast(w / 2)), @as(i64, @intCast(y)) - @as(i64, @intCast(h / 2)), 1);
                }
            }
        }
        var x: i64 = 0;
        var y: i64 = 0;
        var dx: i64 = 0;
        var dy: i64 = -1;
        var infected: u32 = 0;
        var bursts: u32 = 0;
        while (bursts < 10_000) : (bursts += 1) {
            const cur = v.get(x, y);
            if (cur == 1) {
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
            const nv: u8 = 1 - cur;
            if (nv == 1) infected += 1;
            try v.put(x, y, nv);
            x += dx;
            y += dy;
        }
        print("part 1: {d}\n", .{infected});
    }

    // Part 2: 4-state, 10M bursts.
    {
        var grid = Map([2]i64, u8).init(gpa);
        defer grid.deinit();
        var v = V{ .grid = grid };
        for (0..h) |y| {
            for (0..w) |x| {
                if (initial[y][x] == 1) {
                    try v.put(@as(i64, @intCast(x)) - @as(i64, @intCast(w / 2)), @as(i64, @intCast(y)) - @as(i64, @intCast(h / 2)), 2);
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
            const cur = v.get(x, y);
            switch (cur) {
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
                    const t = dx;
                    dx = -t;
                    dy = -dy;
                },
            }
            const nv: u8 = (cur + 1) % 4;
            if (nv == 2) infected += 1;
            try v.put(x, y, nv);
            x += dx;
            y += dy;
        }
        print("part 2: {d}\n", .{infected});
    }
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
// Only unmodified days will be updated.
