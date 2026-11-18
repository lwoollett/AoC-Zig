const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day20.txt");

const P = [2]i64;

var algo: [512]u8 = undefined;

const Grid = struct {
    cells: [][]u8, // 0/1
    outside: bool,

    fn w(self: *const Grid) usize {
        return self.cells[0].len;
    }
    fn h(self: *const Grid) usize {
        return self.cells.len;
    }
    fn at(self: *const Grid, x: i64, y: i64) u8 {
        if (x < 0 or y < 0 or y >= self.h() or x >= self.w()) {
            return @intFromBool(self.outside);
        }
        return self.cells[@intCast(y)][@intCast(x)];
    }
};

fn step(g: *const Grid) !Grid {
    const nw = g.w() + 2;
    const nh = g.h() + 2;
    const cells = try gpa.alloc([]u8, nh);
    for (cells) |*r| {
        r.* = try gpa.alloc(u8, nw);
    }
    var next = Grid{ .cells = cells, .outside = false };
    for (0..nh) |y| {
        for (0..nw) |x| {
            // cell (x,y) in new grid corresponds to (x-1, y-1) in the old
            var index: usize = 0;
            var dy: i64 = -1;
            while (dy <= 1) : (dy += 1) {
                var dx: i64 = -1;
                while (dx <= 1) : (dx += 1) {
                    index <<= 1;
                    const v = g.at(@as(i64, @intCast(x)) + dx - 1, @as(i64, @intCast(y)) + dy - 1);
                    if (v == 1) index |= 1;
                }
            }
            next.cells[y][x] = @intFromBool(algo[index] == '#');
        }
    }
    next.outside = if (g.outside) algo[511] == '#' else algo[0] == '#';
    return next;
}

fn countLit(g: *const Grid) u64 {
    var total: u64 = 0;
    for (g.cells) |row| {
        for (row) |c| {
            if (c == 1) total += 1;
        }
    }
    return total;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    const algo_line = lines.next().?;
    for (algo_line, 0..) |c, i| {
        algo[i] = c;
    }

    var img: List([]const u8) = .empty;
    defer img.deinit(gpa);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try img.append(gpa, line);
    }

    // build the grid with 1-cell padding
    const pad: usize = 1;
    const gw = img.items[0].len + pad * 2;
    const gh = img.items.len + pad * 2;
    var cells = try gpa.alloc([]u8, gh);
    for (cells) |*r| r.* = try gpa.alloc(u8, gw);
    for (cells) |*r| @memset(r.*, 0);
    for (img.items, 0..) |line, y| {
        for (line, 0..) |c, x| {
            cells[y + pad][x + pad] = @intFromBool(c == '#');
        }
    }
    var g = Grid{ .cells = cells, .outside = false };

    var i: usize = 0;
    while (i < 50) : (i += 1) {
        const old = g;
        g = try step(&old);
        for (old.cells) |r| gpa.free(r);
        gpa.free(old.cells);
        if (i == 1) {
            print("part 1: {d}\n", .{countLit(&g)});
        }
    }
    print("part 2: {d}\n", .{countLit(&g)});
    for (g.cells) |r| gpa.free(r);
    gpa.free(g.cells);
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
