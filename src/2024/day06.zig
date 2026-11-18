const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day06.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var h: usize = 0;
var w: usize = 0;

const State = struct { x: usize, y: usize, dir: u8 };

fn patrol(sx: usize, sy: usize, sdir: u8, visited: *Map([2]usize, void)) !bool {
    var x = sx;
    var y = sy;
    var dir = sdir;
    var seen = Map([3]usize, void).init(gpa);
    defer seen.deinit();
    while (true) {
        try visited.put(.{ x, y }, {});
        const key = [3]usize{ x, y, dir };
        if (seen.contains(key)) return true; // loop
        try seen.put(key, {});
        const dx = [4]i64{ 0, 1, 0, -1 };
        const dy = [4]i64{ -1, 0, 1, 0 };
        const nx = @as(i64, @intCast(x)) + dx[dir];
        const ny = @as(i64, @intCast(y)) + dy[dir];
        if (nx < 0 or ny < 0 or nx >= w or ny >= h) return false; // out
        if (grid[@intCast(ny)][@intCast(nx)] == '#') {
            dir = (dir + 1) % 4;
            continue;
        }
        x = @intCast(nx);
        y = @intCast(ny);
    }
}

pub fn main() !void {
    var sx: usize = 0;
    var sy: usize = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        for (line, 0..) |c, x| {
            if (c == '^') {
                sx = x;
                sy = h;
            }
        }
        w = @max(w, line.len);
        h += 1;
    }

    var visited = Map([2]usize, void).init(gpa);
    defer visited.deinit();
    _ = try patrol(sx, sy, 0, &visited);
    print("part 1: {d}\n", .{visited.count()});

    // part 2: try each visited cell as an obstruction
    var loops: u32 = 0;
    var it = visited.keyIterator();
    while (it.next()) |cell| {
        if (cell[0] == sx and cell[1] == sy) continue;
        const orig = grid[cell[1]][cell[0]];
        grid[cell[1]][cell[0]] = '#';
        var v2 = Map([2]usize, void).init(gpa);
        defer v2.deinit();
        if (try patrol(sx, sy, 0, &v2)) {
            loops += 1;
        }
        grid[cell[1]][cell[0]] = orig;
    }
    print("part 2: {d}\n", .{loops});
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
