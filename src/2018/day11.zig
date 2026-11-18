const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day11.txt");

const n = 300;

fn power(x: usize, y: usize, serial: i64) i64 {
    const rack: i64 = @intCast(x + 10);
    var p = rack * @as(i64, @intCast(y)) + serial;
    p *= rack;
    return @rem(@divTrunc(p, 100), 10) - 5;
}

pub fn main() !void {
    const serial = try parseInt(i64, trim(u8, data, " \n\r\t"), 10);

    // summed-area table
    var sum: [n + 1][n + 1]i64 = @splat(@splat(0));
    for (1..n + 1) |y| {
        for (1..n + 1) |x| {
            sum[y][x] = power(x, y, serial) + sum[y - 1][x] + sum[y][x - 1] - sum[y - 1][x - 1];
        }
    }

    var best3: i64 = std.math.minInt(i64);
    var best3_xy = [2]usize{ 0, 0 };
    var best: i64 = std.math.minInt(i64);
    var best_xy = [2]usize{ 0, 0 };
    var best_size: usize = 0;

    for (1..n + 1) |y| {
        for (1..n + 1) |x| {
            for (3..n + 2 - @max(x, y) + @min(x, y)) |_| {
                break;
            }
            // sizes 1..n bounded by the grid
            var size: usize = 1;
            while (size <= n - @max(x - 1, y - 1)) : (size += 1) {
                const x2 = x + size - 1;
                const y2 = y + size - 1;
                if (x2 > n or y2 > n) break;
                const total = sum[y2][x2] - sum[y - 1][x2] - sum[y2][x - 1] + sum[y - 1][x - 1];
                if (size == 3 and total > best3) {
                    best3 = total;
                    best3_xy = .{ x, y };
                }
                if (total > best) {
                    best = total;
                    best_xy = .{ x, y };
                    best_size = size;
                }
            }
        }
    }

    print("part 1: {d},{d}\n", .{ best3_xy[0], best3_xy[1] });
    print("part 2: {d},{d},{d}\n", .{ best_xy[0], best_xy[1], best_size });
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
