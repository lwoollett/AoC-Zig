const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day12.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var h: usize = 0;
var w: usize = 0;

const Cell = [2]usize;

/// flood-fill a region; returns area and side count (p2 semantics; for p1
/// use the edge count variant)
fn region(cx: usize, cy: usize, visited: *Map(Cell, void)) !struct { area: u64, perim: u64, sides: u64 } {
    const plant = grid[cy][cx];
    var area: u64 = 0;
    var perim: u64 = 0;
    var q: List(Cell) = .empty;
    defer q.deinit(gpa);
    try visited.put(.{ cx, cy }, {});
    try q.append(gpa, .{ cx, cy });
    var cells: List(Cell) = .empty;
    defer cells.deinit(gpa);
    var head: usize = 0;
    while (head < q.items.len) : (head += 1) {
        const cur = q.items[head];
        area += 1;
        try cells.append(gpa, cur);
        const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
        for (deltas) |d| {
            const nx = @as(i32, @intCast(cur[0])) + d[0];
            const ny = @as(i32, @intCast(cur[1])) + d[1];
            if (nx < 0 or ny < 0 or nx >= w or ny >= h or grid[@intCast(ny)][@intCast(nx)] != plant) {
                perim += 1;
                continue;
            }
            const key = Cell{ @intCast(nx), @intCast(ny) };
            if (!visited.contains(key)) {
                try visited.put(key, {});
                try q.append(gpa, key);
            }
        }
    }
    // sides: count corners. A corner exists at cell c, corner-direction k,
    // when the two adjacent sides are edge AND the diagonal is edge (convex),
    // or both sides are same-plant AND the diagonal is edge (concave).
    var sides: u64 = 0;
    const nd = [4][2]i32{ .{ 0, -1 }, .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 } }; // N E S W
    for (cells.items) |c| {
        for (0..4) |k| {
            const d1 = nd[k];
            const d2 = nd[(k + 1) % 4];
            const s1_out = outOrDiff(c, d1, plant);
            const s2_out = outOrDiff(c, d2, plant);
            const diag = [2]i32{ d1[0] + d2[0], d1[1] + d2[1] };
            const diag_out = outOrDiff(c, diag, plant);
            if (s1_out and s2_out) sides += 1; // convex corner
            if (!s1_out and !s2_out and diag_out) sides += 1; // concave corner
        }
    }
    return .{ .area = area, .perim = perim, .sides = sides };
}

fn outOrDiff(c: Cell, d: [2]i32, plant: u8) bool {
    const nx = @as(i32, @intCast(c[0])) + d[0];
    const ny = @as(i32, @intCast(c[1])) + d[1];
    if (nx < 0 or ny < 0 or nx >= w or ny >= h) return true;
    return grid[@intCast(ny)][@intCast(nx)] != plant;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    var visited = Map(Cell, void).init(gpa);
    defer visited.deinit();
    var total1: u64 = 0;
    var total2: u64 = 0;
    for (0..h) |y| {
        for (0..w) |x| {
            if (!visited.contains(.{ x, y })) {
                const r = try region(x, y, &visited);
                total1 += r.area * r.perim;
                total2 += r.area * r.sides;
            }
        }
    }
    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{total2});
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
