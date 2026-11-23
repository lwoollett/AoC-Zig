const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day24.txt");

var w: usize = 0;
var h: usize = 0;
var walls: [40][120]bool = @splat(@splat(false));
var bliz0: List([3]i32) = .empty; // x, y, dir (0=R,1=D,2=L,3=U)

const dx = [4]i32{ 1, 0, -1, 0 };
const dy = [4]i32{ 0, 1, 0, -1 };

// occupancy bitsets per time step: blizzards repeat with period
// lcm(w-2, h-2); precompute once instead of scanning every blizzard
// per neighbor check in the BFS.
var occ: []u64 = &.{}; // [period][w*h/64] bit per cell
var period: usize = 0;

fn buildOccupancy() !void {
    const wx: usize = w - 2;
    const hx: usize = h - 2;
    var g: usize = wx;
    var a: usize = hx;
    while (a != 0) {
        const tmp = g % a;
        g = a;
        a = tmp;
    }
    period = wx / g * hx;
    const words = (w * h + 63) / 64;
    occ = try gpa.alloc(u64, period * words);
    @memset(occ, 0);
    for (bliz0.items) |b| {
        var t: usize = 0;
        while (t < period) : (t += 1) {
            const bx = @mod(b[0] + dx[@intCast(b[2])] * @as(i32, @intCast(t)) - 1, @as(i32, @intCast(wx))) + 1;
            const by = @mod(b[1] + dy[@intCast(b[2])] * @as(i32, @intCast(t)) - 1, @as(i32, @intCast(hx))) + 1;
            const cell = @as(usize, @intCast(by)) * w + @as(usize, @intCast(bx));
            occ[t * words + cell / 64] |= @as(u64, 1) << @intCast(cell % 64);
        }
    }
}

fn blizzardAt(t: usize, x: usize, y: usize) bool {
    const words = (w * h + 63) / 64;
    const tt = t % period;
    const cell = y * w + x;
    return occ[tt * words + cell / 64] & (@as(u64, 1) << @intCast(cell % 64)) != 0;
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

    try buildOccupancy();

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
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
