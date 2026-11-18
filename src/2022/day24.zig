const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day24.txt");

var w: usize = 0;
var h: usize = 0;
var walls: [40][120]bool = @splat(@splat(false));
var bliz0: List([3]i32) = .empty; // x, y, dir (0=R,1=D,2=L,3=U)

const dx = [4]i32{ 1, 0, -1, 0 };
const dy = [4]i32{ 0, 1, 0, -1 };

fn blizzardAt(t: usize, x: usize, y: usize) bool {
    // a cell is blocked if any blizzard is there at time t
    for (bliz0.items) |b| {
        var bx = b[0];
        var by = b[1];
        // advance mod the inner area
        bx = @mod(bx + dx[@intCast(b[2])] * @as(i32, @intCast(t)) - 1, @as(i32, @intCast(w - 2))) + 1;
        by = @mod(by + dy[@intCast(b[2])] * @as(i32, @intCast(t)) - 1, @as(i32, @intCast(h - 2))) + 1;
        if (bx == x and by == y) return true;
    }
    return false;
}

const State = struct { x: usize, y: usize, t: usize };

/// BFS from (sx, sy) at time t0 to (gx, gy).
fn trip(sx: usize, sy: usize, gx: usize, gy: usize, t0: usize) !usize {
    var visited = Map([3]usize, void).init(gpa);
    defer visited.deinit();
    var q: List(State) = .empty;
    defer q.deinit(gpa);
    try q.append(gpa, .{ .x = sx, .y = sy, .t = t0 });
    try visited.put(.{ sx, sy, t0 }, {});
    var head: usize = 0;
    while (head < q.items.len) : (head += 1) {
        const cur = q.items[head];
        if (cur.x == gx and cur.y == gy) return cur.t;
        const nt = cur.t + 1;
        for (0..5) |k| {
            var nx: i64 = @intCast(cur.x);
            var ny: i64 = @intCast(cur.y);
            if (k < 4) {
                nx += dx[k];
                ny += dy[k];
            }
            if (nx < 0 or ny < 0 or nx >= w or ny >= h) continue;
            if (walls[@intCast(ny)][@intCast(nx)]) continue;
            const key = [3]usize{ @intCast(nx), @intCast(ny), nt };
            if (visited.contains(key)) continue;
            if (blizzardAt(nt, @intCast(nx), @intCast(ny))) continue;
            try visited.put(key, {});
            try q.append(gpa, .{ .x = @intCast(nx), .y = @intCast(ny), .t = nt });
        }
    }
    return error.NoPath;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        w = @max(w, line.len);
        for (line, 0..) |c, x| {
            switch (c) {
                '#' => walls[h][x] = true,
                '>' => try bliz0.append(gpa, .{ @intCast(x), @intCast(h), 0 }),
                'v' => try bliz0.append(gpa, .{ @intCast(x), @intCast(h), 1 }),
                '<' => try bliz0.append(gpa, .{ @intCast(x), @intCast(h), 2 }),
                '^' => try bliz0.append(gpa, .{ @intCast(x), @intCast(h), 3 }),
                else => {},
            }
        }
        h += 1;
    }

    // start: top row gap; goal: bottom row gap
    var sx: usize = 0;
    var gx: usize = 0;
    for (0..w) |x| {
        if (!walls[0][x]) sx = x;
        if (!walls[h - 1][x]) gx = x;
    }

    const t1 = try trip(sx, 0, gx, h - 1, 0);
    print("part 1: {d}\n", .{t1});
    const t2 = try trip(gx, h - 1, sx, 0, t1);
    const t3 = try trip(sx, 0, gx, h - 1, t2);
    print("part 2: {d}\n", .{t3});
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
