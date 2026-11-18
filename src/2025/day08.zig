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

const P = [3]i64;

const Pair = struct { d: u64, i: usize, j: usize };

var parent: List(usize) = .empty;

fn find(x: usize) usize {
    if (parent.items[x] == x) return x;
    parent.items[x] = find(parent.items[x]);
    return parent.items[x];
}

fn unionBoxes(a: usize, b: usize) void {
    const ra = find(a);
    const rb = find(b);
    if (ra != rb) {
        parent.items[ra] = rb;
    }
}

pub fn main() !void {
    var pts: List(P) = .empty;
    defer pts.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeSca(u8, line, ',');
        const x = try parseInt(i64, it.next().?, 10);
        const y = try parseInt(i64, it.next().?, 10);
        const z = try parseInt(i64, it.next().?, 10);
        try pts.append(gpa, .{ x, y, z });
    }
    const n = pts.items.len;

    for (0..n) |i| {
        try parent.append(gpa, i);
    }

    // all pairs by squared distance
    var pairs: List(Pair) = .empty;
    defer pairs.deinit(gpa);
    for (pts.items, 0..) |a, i| {
        for (pts.items[i + 1 ..], i + 1..) |b, j| {
            const dx = a[0] - b[0];
            const dy = a[1] - b[1];
            const dz = a[2] - b[2];
            const d2: u64 = @intCast(dx * dx + dy * dy + dz * dz);
            try pairs.append(gpa, .{ .d = d2, .i = i, .j = j });
        }
    }
    std.mem.sort(Pair, pairs.items, {}, struct {
        fn lessThan(_: void, a: Pair, b: Pair) bool {
            if (a.d != b.d) return a.d < b.d;
            if (a.i != b.i) return a.i < b.i;
            return a.j < b.j;
        }
    }.lessThan);

    // connect the 1000 closest
    var connected: usize = 0;
    for (pairs.items) |p| {
        if (connected >= 1000) break;
        unionBoxes(p.i, p.j);
        connected += 1;
    }

    // component sizes
    var size = try gpa.alloc(u64, n);
    defer gpa.free(size);
    @memset(size, 0);
    for (0..n) |i| {
        size[find(i)] += 1;
    }
    var top: [3]u64 = .{ 0, 0, 0 };
    for (size) |s| {
        if (s > top[0]) {
            top[2] = top[1];
            top[1] = top[0];
            top[0] = s;
        } else if (s > top[1]) {
            top[2] = top[1];
            top[1] = s;
        } else if (s > top[2]) {
            top[2] = s;
        }
    }
    print("part 1: {d}\n", .{top[0] * top[1] * top[2]});
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
