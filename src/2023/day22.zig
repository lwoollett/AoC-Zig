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

const Brick = struct {
    x0: i64,
    y0: i64,
    z0: i64,
    x1: i64,
    y1: i64,
    z1: i64,
};

var bricks: List(Brick) = .empty;

/// settle all bricks; returns how many moved
fn settle() !usize {
    std.mem.sort(Brick, bricks.items, {}, struct {
        fn lessThan(_: void, a: Brick, b: Brick) bool {
            return a.z0 < b.z0;
        }
    }.lessThan);
    var moved: usize = 0;
    // top surface map: [x][y] = highest z occupied
    var top = try gpa.alloc([]i64, 400);
    defer {
        for (top) |r| gpa.free(r);
        gpa.free(top);
    }
    for (top) |*r| {
        r.* = try gpa.alloc(i64, 400);
        @memset(r.*, 0);
    }
    for (bricks.items) |*b| {
        var landing: i64 = 0;
        var x = b.x0;
        while (x <= b.x1) : (x += 1) {
            var y = b.y0;
            while (y <= b.y1) : (y += 1) {
                landing = @max(landing, top[@intCast(x)][@intCast(y)]);
            }
        }
        const height = b.z1 - b.z0;
        if (b.z0 != landing) moved += 1;
        b.z0 = landing;
        b.z1 = landing + height;
        x = b.x0;
        while (x <= b.x1) : (x += 1) {
            var y = b.y0;
            while (y <= b.y1) : (y += 1) {
                top[@intCast(x)][@intCast(y)] = b.z1 + 1;
            }
        }
    }
    return moved;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "1,0,1~1,2,1"
        const tilde = indexOf(u8, line, '~').?;
        var c1: [3]i64 = undefined;
        var c2: [3]i64 = undefined;
        var it1 = tokenizeSca(u8, line[0..tilde], ',');
        var i: usize = 0;
        while (it1.next()) |tok| : (i += 1) {
            c1[i] = try parseInt(i64, tok, 10);
        }
        var it2 = tokenizeSca(u8, line[tilde + 1 ..], ',');
        i = 0;
        while (it2.next()) |tok| : (i += 1) {
            c2[i] = try parseInt(i64, tok, 10);
        }
        try bricks.append(gpa, .{
            .x0 = @min(c1[0], c2[0]),
            .y0 = @min(c1[1], c2[1]),
            .z0 = @min(c1[2], c2[2]),
            .x1 = @max(c1[0], c2[0]),
            .y1 = @max(c1[1], c2[1]),
            .z1 = @max(c1[2], c2[2]),
        });
    }

    _ = try settle();

    // for each brick: remove it, re-settle, count moved
    var safe: usize = 0;
    var total_falls: usize = 0;
    for (bricks.items, 0..) |_, bi| {
        // snapshot
        const snapshot = try gpa.dupe(Brick, bricks.items);
        defer gpa.free(snapshot);
        _ = bricks.orderedRemove(bi);
        const moved = try settle();
        if (moved == 0) safe += 1;
        total_falls += moved;
        // restore
        bricks.clearRetainingCapacity();
        try bricks.appendSlice(gpa, snapshot);
    }

    print("part 1: {d}\n", .{safe});
    print("part 2: {d}\n", .{total_falls});
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
