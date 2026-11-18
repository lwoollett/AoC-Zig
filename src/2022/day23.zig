const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day23.txt");

const P = [2]i32;

var elves = List(P).empty;

const all_n = [8][2]i32{
    .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 },
    .{ -1, 0 },  .{ 1, 0 },  .{ -1, 1 },
    .{ 0, 1 },   .{ 1, 1 },
};

const dir_sets = [4][3][2]i32{
    .{ .{ 0, -1 }, .{ -1, -1 }, .{ 1, -1 } }, // N, NE, NW
    .{ .{ 0, 1 }, .{ -1, 1 }, .{ 1, 1 } }, // S, SE, SW
    .{ .{ -1, 0 }, .{ -1, -1 }, .{ -1, 1 } }, // W, NW, SW
    .{ .{ 1, 0 }, .{ 1, -1 }, .{ 1, 1 } }, // E, NE, SE
};

fn round(pos: *Map(P, void), first_dir: u8) !bool {
    var proposals = Map(P, P).init(gpa);
    defer proposals.deinit();
    var counts = Map(P, u32).init(gpa);
    defer counts.deinit();

    var it = pos.keyIterator();
    while (it.next()) |e| {
        const p = e.*;
        // any neighbors?
        var any = false;
        for (all_n) |n| {
            if (pos.contains(.{ p[0] + n[0], p[1] + n[1] })) any = true;
        }
        if (!any) continue;
        for (0..4) |k| {
            const d = (first_dir + @as(u8, @intCast(k))) % 4;
            const set = dir_sets[d];
            var clear = true;
            for (set) |n| {
                if (pos.contains(.{ p[0] + n[0], p[1] + n[1] })) clear = false;
            }
            if (clear) {
                const target = P{ p[0] + set[0][0], p[1] + set[0][1] };
                try proposals.put(p, target);
                const gop = try counts.getOrPut(target);
                if (!gop.found_existing) gop.value_ptr.* = 0;
                gop.value_ptr.* += 1;
                break;
            }
        }
    }

    var moved = false;
    var pit = proposals.iterator();
    while (pit.next()) |e| {
        if (counts.get(e.value_ptr.*).? == 1) {
            _ = pos.remove(e.key_ptr.*);
            try pos.put(e.value_ptr.*, {});
            moved = true;
        }
    }
    return moved;
}

fn runRounds(n: usize) !usize {
    var pos = Map(P, void).init(gpa);
    defer pos.deinit();
    for (elves.items) |e| {
        try pos.put(e, {});
    }
    var r: usize = 0;
    while (r < n) : (r += 1) {
        _ = try round(&pos, @intCast(r % 4));
    }
    // bounding box
    var lo = P{ std.math.maxInt(i32), std.math.maxInt(i32) };
    var hi = P{ std.math.minInt(i32), std.math.minInt(i32) };
    var it = pos.keyIterator();
    while (it.next()) |e| {
        lo[0] = @min(lo[0], e[0]);
        lo[1] = @min(lo[1], e[1]);
        hi[0] = @max(hi[0], e[0]);
        hi[1] = @max(hi[1], e[1]);
    }
    return @intCast((hi[0] - lo[0] + 1) * (hi[1] - lo[1] + 1) - @as(i32, @intCast(pos.count())));
}

fn runUntilStable() !usize {
    var pos = Map(P, void).init(gpa);
    defer pos.deinit();
    for (elves.items) |e| {
        try pos.put(e, {});
    }
    var r: usize = 0;
    while (true) : (r += 1) {
        const moved = try round(&pos, @intCast(r % 4));
        if (!moved) return r + 1;
    }
}

pub fn main() !void {
    var y: usize = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| : (y += 1) {
        for (line, 0..) |c, x| {
            if (c == '#') {
                try elves.append(gpa, .{ @intCast(x), @intCast(y) });
            }
        }
    }
    print("part 1: {d}\n", .{try runRounds(10)});
    print("part 2: {d}\n", .{try runUntilStable()});
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
