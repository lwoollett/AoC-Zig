const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day08.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var h: usize = 0;
var w: usize = 0;

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    // antennas grouped by frequency
    var freqs = Map(u8, List([2]i64)).init(gpa);
    defer {
        var dit = freqs.valueIterator();
        while (dit.next()) |l| l.deinit(gpa);
        freqs.deinit();
    }
    for (0..h) |y| {
        for (0..w) |x| {
            const c = grid[y][x];
            if (c != '.') {
                const gop = try freqs.getOrPut(c);
                if (!gop.found_existing) gop.value_ptr.* = .empty;
                try gop.value_ptr.append(gpa, .{ @intCast(x), @intCast(y) });
            }
        }
    }

    // part 1: antinodes at 2x distance
    var anti1 = Map([2]i64, void).init(gpa);
    defer anti1.deinit();
    var anti2 = Map([2]i64, void).init(gpa);
    defer anti2.deinit();

    var fit = freqs.iterator();
    while (fit.next()) |e| {
        const pts = e.value_ptr.items;
        for (pts, 0..) |a, i| {
            for (pts[i + 1 ..]) |b| {
                // antinodes: a + (a-b) and b + (b-a)
                const d1 = [2]i64{ 2 * a[0] - b[0], 2 * a[1] - b[1] };
                const d2 = [2]i64{ 2 * b[0] - a[0], 2 * b[1] - a[1] };
                for ([2][2]i64{ d1, d2 }) |p| {
                    if (p[0] >= 0 and p[1] >= 0 and p[0] < w and p[1] < h) {
                        try anti1.put(p, {});
                    }
                }
                // part 2: all points on the line through a and b (within grid)
                var dx = b[0] - a[0];
                var dy = b[1] - a[1];
                // reduce direction
                const g0 = std.math.gcd(@abs(dx), @abs(dy));
                dx = @divTrunc(dx, @as(i64, @intCast(g0)));
                dy = @divTrunc(dy, @as(i64, @intCast(g0)));
                var p = a;
                while (p[0] >= 0 and p[1] >= 0 and p[0] < w and p[1] < h) {
                    try anti2.put(p, {});
                    p = .{ p[0] + dx, p[1] + dy };
                }
                p = a;
                while (p[0] >= 0 and p[1] >= 0 and p[0] < w and p[1] < h) {
                    try anti2.put(p, {});
                    p = .{ p[0] - dx, p[1] - dy };
                }
            }
        }
    }
    print("part 1: {d}\n", .{anti1.count()});
    print("part 2: {d}\n", .{anti2.count()});
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
