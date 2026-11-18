const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day13.txt");

const P = [2]i64;

pub fn main() !void {
    var dots = Map(P, void).init(gpa);
    defer dots.deinit();
    var folds: List(P) = .empty; // P{axis(0=x,1=y), line}
    defer folds.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    var in_folds = false;
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "fold along ")) {
            in_folds = true;
            const eq = indexOf(u8, line, '=').?;
            const axis: i64 = if (line[eq - 1] == 'x') 0 else 1;
            const v = try parseInt(i64, line[eq + 1 ..], 10);
            try folds.append(gpa, .{ axis, v });
            continue;
        }
        if (in_folds or line.len == 0) continue;
        const comma = indexOf(u8, line, ',').?;
        const x = try parseInt(i64, line[0..comma], 10);
        const y = try parseInt(i64, line[comma + 1 ..], 10);
        try dots.put(.{ x, y }, {});
    }

    var first_count: ?usize = null;
    for (folds.items) |f| {
        var next = Map(P, void).init(gpa);
        var it = dots.keyIterator();
        while (it.next()) |p| {
            var q = p.*;
            if (q[@intCast(f[0])] > f[1]) {
                q[@intCast(f[0])] = 2 * f[1] - q[@intCast(f[0])];
            }
            try next.put(q, {});
        }
        dots.deinit();
        dots = next;
        if (first_count == null) first_count = dots.count();
    }
    print("part 1: {d}\n", .{first_count.?});

    // part 2: render
    var max_x: i64 = 0;
    var max_y: i64 = 0;
    var it = dots.keyIterator();
    while (it.next()) |p| {
        max_x = @max(max_x, p[0]);
        max_y = @max(max_y, p[1]);
    }
    for (0..@intCast(max_y + 1)) |y| {
        for (0..@intCast(max_x + 1)) |x| {
            const on = dots.contains(.{ @intCast(x), @intCast(y) });
            print("{s}", .{if (on) "#" else " "});
        }
        print("\n", .{});
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
