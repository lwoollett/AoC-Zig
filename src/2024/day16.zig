const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day16.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat('#'));
var h: usize = 0;
var w: usize = 0;

const State = struct { x: usize, y: usize, dir: u8 };
const dx = [4]i64{ 1, 0, -1, 0 };
const dy = [4]i64{ 0, 1, 0, -1 };

/// Dijkstra over (x, y, dir); fills dist map. Returns the min score to E.
fn solve(dist: *Map([4]u64, u64)) !u64 {
    // find S and E
    var sx: usize = 0;
    var sy: usize = 0;
    var ex: usize = 0;
    var ey: usize = 0;
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == 'S') {
                sx = x;
                sy = y;
            }
            if (grid[y][x] == 'E') {
                ex = x;
                ey = y;
            }
        }
    }

    const Item = struct { cost: u64, s: State };
    var pq = std.PriorityQueue(Item, void, struct {
        fn lessThan(_: void, a: Item, b: Item) std.math.Order {
            return std.math.order(a.cost, b.cost);
        }
    }.lessThan).initContext({});
    defer pq.deinit(gpa);

    try dist.put(.{ sx, sy, 0, 0 }, 0);
    try pq.push(gpa, .{ .cost = 0, .s = .{ .x = sx, .y = sy, .dir = 0 } });

    var best: ?u64 = null;
    while (pq.pop()) |cur| {
        if (best) |b| {
            if (cur.cost > b) break;
        }
        if (cur.s.x == ex and cur.s.y == ey) {
            if (best == null or cur.cost < best.?) best = cur.cost;
            continue;
        }
        const key = [4]u64{ cur.s.x, cur.s.y, cur.s.dir, 0 };
        if ((dist.get(key) orelse std.math.maxInt(u64)) < cur.cost) continue;

        // moves: forward (cost 1), turn left/right (cost 1000)
        const fx = @as(i64, @intCast(cur.s.x)) + dx[cur.s.dir];
        const fy = @as(i64, @intCast(cur.s.y)) + dy[cur.s.dir];
        if (fx >= 0 and fy >= 0 and fx < w and fy < h and grid[@intCast(fy)][@intCast(fx)] != '#') {
            const nk = [4]u64{ @intCast(fx), @intCast(fy), cur.s.dir, 0 };
            const nc = cur.cost + 1;
            if (nc < dist.get(nk) orelse std.math.maxInt(u64)) {
                try dist.put(nk, nc);
                try pq.push(gpa, .{ .cost = nc, .s = .{ .x = @intCast(fx), .y = @intCast(fy), .dir = cur.s.dir } });
            }
        }
        for ([2]u8{ (cur.s.dir + 3) % 4, (cur.s.dir + 1) % 4 }) |nd| {
            const nk = [4]u64{ cur.s.x, cur.s.y, nd, 0 };
            const nc = cur.cost + 1000;
            if (nc < dist.get(nk) orelse std.math.maxInt(u64)) {
                try dist.put(nk, nc);
                try pq.push(gpa, .{ .cost = nc, .s = .{ .x = cur.s.x, .y = cur.s.y, .dir = nd } });
            }
        }
    }
    return best orelse error.NoPath;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    var dist = Map([4]u64, u64).init(gpa);
    defer dist.deinit();
    const best = try solve(&dist);
    print("part 1: {d}\n", .{best});

    // part 2: all tiles on any optimal path — walk back from end states
    var on_best = Map([2]usize, void).init(gpa);
    defer on_best.deinit();
    var queue: List(State) = .empty;
    defer queue.deinit(gpa);
    var seen = Map(State, void).init(gpa);
    defer seen.deinit();

    // find E position
    var ex: usize = 0;
    var ey: usize = 0;
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == 'E') {
                ex = x;
                ey = y;
            }
        }
    }
    for (0..4) |d| {
        const k = [4]u64{ ex, ey, d, 0 };
        if (dist.get(k)) |c| {
            if (c == best) {
                try queue.append(gpa, .{ .x = ex, .y = ey, .dir = @intCast(d) });
                try seen.put(.{ .x = ex, .y = ey, .dir = @intCast(d) }, {});
            }
        }
    }
    while (queue.pop()) |s| {
        try on_best.put(.{ s.x, s.y }, {});
        const cost = dist.get(.{ s.x, s.y, s.dir, 0 }) orelse continue;
        // predecessors: came from behind (moving forward), or same cell turned
        const bx = @as(i64, @intCast(s.x)) - dx[s.dir];
        const by = @as(i64, @intCast(s.y)) - dy[s.dir];
        if (bx >= 0 and by >= 0 and bx < w and by < h and grid[@intCast(by)][@intCast(bx)] != '#') {
            const pk = [4]u64{ @intCast(bx), @intCast(by), s.dir, 0 };
            if (dist.get(pk)) |pc| {
                if (pc + 1 == cost) {
                    const ps = State{ .x = @intCast(bx), .y = @intCast(by), .dir = s.dir };
                    if (!seen.contains(ps)) {
                        try seen.put(ps, {});
                        try queue.append(gpa, ps);
                    }
                }
            }
        }
        for ([2]u8{ (s.dir + 3) % 4, (s.dir + 1) % 4 }) |pd| {
            const pk = [4]u64{ s.x, s.y, pd, 0 };
            if (dist.get(pk)) |pc| {
                if (pc + 1000 == cost) {
                    const ps = State{ .x = s.x, .y = s.y, .dir = pd };
                    if (!seen.contains(ps)) {
                        try seen.put(ps, {});
                        try queue.append(gpa, ps);
                    }
                }
            }
        }
    }
    print("part 2: {d}\n", .{on_best.count()});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
