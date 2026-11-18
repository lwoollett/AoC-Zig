const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day09.txt");

const gw = 128;
const gh = 128;
var grid: [gh][gw]u8 = @splat(@splat('9'));
var h: usize = 0;
var w: usize = 0;

fn basinSize(x0: usize, y0: usize) u32 {
    var seen = Map([2]usize, void).init(gpa);
    defer seen.deinit();
    var q: List([2]usize) = .empty;
    defer q.deinit(gpa);
    q.append(gpa, .{ x0, y0 }) catch return 0;
    seen.put(.{ x0, y0 }, {}) catch return 0;
    var head: usize = 0;
    while (head < q.items.len) : (head += 1) {
        const cur = q.items[head];
        const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
        for (deltas) |dl| {
            const nx = @as(i32, @intCast(cur[0])) + dl[0];
            const ny = @as(i32, @intCast(cur[1])) + dl[1];
            if (nx < 0 or ny < 0 or nx >= gw or ny >= gh) continue;
            const x: usize = @intCast(nx);
            const y: usize = @intCast(ny);
            if (x >= w or y >= h) continue;
            if (grid[y][x] == '9') continue;
            const key = [2]usize{ x, y };
            if (seen.contains(key)) continue;
            seen.put(key, {}) catch return 0;
            q.append(gpa, key) catch return 0;
        }
    }
    // don't count the seed twice (it's in seen once)
    return seen.count();
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    var risk: u64 = 0;
    var basins: List(u32) = .empty;
    defer basins.deinit(gpa);

    for (0..h) |y| {
        for (0..w) |x| {
            const v = grid[y][x];
            var low = true;
            const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
            for (deltas) |dl| {
                const nx = @as(i32, @intCast(x)) + dl[0];
                const ny = @as(i32, @intCast(y)) + dl[1];
                if (nx < 0 or ny < 0 or nx >= gw or ny >= gh) continue;
                const xx: usize = @intCast(nx);
                const yy: usize = @intCast(ny);
                if (xx >= w or yy >= h) continue;
                if (grid[yy][xx] <= v) low = false;
            }
            if (low) {
                risk += v - '0' + 1;
                try basins.append(gpa, basinSize(x, y));
            }
        }
    }
    print("part 1: {d}\n", .{risk});

    std.mem.sort(u32, basins.items, {}, comptime std.sort.desc(u32));
    const product: u64 = @as(u64, basins.items[0]) * basins.items[1] * basins.items[2];
    print("part 2: {d}\n", .{product});
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
