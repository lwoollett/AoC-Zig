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

// reused across rounds — avoids 965x map init/growth churn
var proposals = Map(P, P).init(std.heap.page_allocator);
var counts = Map(P, u32).init(std.heap.page_allocator);
var next_positions = List(P).empty;

fn round(cur: *List(P), pos: *Map(P, void), first_dir: u8) !bool {
    // rebuild pos from the live list: a clean table every round. The previous
    // remove/put-per-mover design leaked tombstones into the table, and at
    // ~95% occupancy every probe (neighbor checks run 12/elf) walked long
    // tombstone chains — per-op cost grew steadily, ~60x by round 965.
    pos.clearRetainingCapacity();
    try pos.ensureTotalCapacity(@intCast(cur.items.len * 2));
    for (cur.items) |e| try pos.put(e, {});

    proposals.clearRetainingCapacity();
    counts.clearRetainingCapacity();

    for (cur.items) |p| {
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
    next_positions.clearRetainingCapacity();
    try next_positions.ensureTotalCapacity(std.heap.page_allocator, cur.items.len);
    for (cur.items) |p| {
        // accepted proposal (unique target)?
        if (proposals.get(p)) |target| {
            if (counts.get(target).? == 1) {
                try next_positions.append(std.heap.page_allocator, target);
                moved = true;
                continue;
            }
        }
        try next_positions.append(std.heap.page_allocator, p);
    }
    std.mem.swap(List(P), cur, &next_positions);
    return moved;
}


fn runRounds(n: usize) !usize {
    var pos = Map(P, void).init(gpa);
    defer pos.deinit();
    var cur = List(P).empty;
    defer cur.deinit(gpa);
    try cur.appendSlice(gpa, elves.items);
    var r: usize = 0;
    while (r < n) : (r += 1) {
        _ = try round(&cur, &pos, @intCast(r % 4));
    }
    // bounding box over the live list (pos lags one round by design)
    var lo = P{ std.math.maxInt(i32), std.math.maxInt(i32) };
    var hi = P{ std.math.minInt(i32), std.math.minInt(i32) };
    for (cur.items) |e| {
        lo[0] = @min(lo[0], e[0]);
        lo[1] = @min(lo[1], e[1]);
        hi[0] = @max(hi[0], e[0]);
        hi[1] = @max(hi[1], e[1]);
    }
    return @intCast((hi[0] - lo[0] + 1) * (hi[1] - lo[1] + 1) - @as(i32, @intCast(cur.items.len)));
}

fn runUntilStable() !usize {
    var pos = Map(P, void).init(gpa);
    defer pos.deinit();
    var cur = List(P).empty;
    defer cur.deinit(gpa);
    try cur.appendSlice(gpa, elves.items);
    var r: usize = 0;
    while (true) : (r += 1) {
        const moved = try round(&cur, &pos, @intCast(r % 4));
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
// Only unmodified days will be updated.
