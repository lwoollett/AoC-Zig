const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day18.txt");

const P = struct { x: usize, y: usize };

const gw = 100;
const gh = 100;

const Edge = struct { to: u8, dist: u32, doors: u32 };

fn keyIndex(c: u8) u8 {
    return c - 'a';
}

fn doorBit(c: u8) u32 {
    return @as(u32, 1) << @intCast(c - 'A');
}

fn keyBit(k: u8) u32 {
    return @as(u32, 1) << @intCast(k);
}

/// BFS from a node's cell over the grid (walls block; doors passable but recorded).
fn buildEdges(grid: [gh][gw]u8, from: P) !List(Edge) {
    var edges: List(Edge) = .empty;
    errdefer edges.deinit(gpa);

    const Cell = struct { dist: u32, doors: u32 };
    var seen: [gh][gw]?Cell = @splat(@splat(@as(?Cell, null)));

    var q: List(P) = .empty;
    defer q.deinit(gpa);
    seen[from.y][from.x] = .{ .dist = 0, .doors = 0 };
    try q.append(gpa, from);

    const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
    var head: usize = 0;
    while (head < q.items.len) : (head += 1) {
        const cur = q.items[head];
        const cd = seen[cur.y][cur.x].?;
        for (deltas) |dl| {
            const nx = @as(i32, @intCast(cur.x)) + dl[0];
            const ny = @as(i32, @intCast(cur.y)) + dl[1];
            if (nx < 0 or ny < 0 or ny >= gh or nx >= gw) continue;
            const x: usize = @intCast(nx);
            const y: usize = @intCast(ny);
            const cell = grid[y][x];
            if (cell == '#') continue;
            if (seen[y][x] != null) continue;
            var doors = cd.doors;
            if (cell >= 'A' and cell <= 'Z') doors |= doorBit(cell);
            seen[y][x] = .{ .dist = cd.dist + 1, .doors = doors };
            if (cell >= 'a' and cell <= 'z') {
                try edges.append(gpa, .{ .to = keyIndex(cell), .dist = cd.dist + 1, .doors = doors });
            }
            try q.append(gpa, .{ .x = x, .y = y });
        }
    }
    return edges;
}

fn solve(grid: [gh][gw]u8, starts: []const P, n_keys: u8) !u64 {
    // nodes: keys 0..n_keys-1, starts n_keys+i
    const N = n_keys + @as(u8, @intCast(starts.len));
    var adj: []List(Edge) = try gpa.alloc(List(Edge), N);
    defer {
        for (adj) |*l| l.deinit(gpa);
        gpa.free(adj);
    }
    for (starts, 0..) |s, i| {
        adj[n_keys + i] = try buildEdges(grid, s);
    }
    for (0..n_keys) |k| {
        // find the key's cell
        var cell: P = .{ .x = 0, .y = 0 };
        found: for (0..gh) |y| {
            for (0..gw) |x| {
                if (grid[y][x] == 'a' + @as(u8, @intCast(k))) {
                    cell = .{ .x = x, .y = y };
                    break :found;
                }
            }
        }
        adj[k] = try buildEdges(grid, cell);
    }

    const all_keys: u32 = if (n_keys >= 32) std.math.maxInt(u32) else (@as(u32, 1) << @intCast(n_keys)) - 1;

    const R = starts.len;
    const State = struct {
        robots: [4]u8 = @splat(0),
        mask: u32 = 0,
    };

    const Item = struct { cost: u64, state: State };
    var pq = std.PriorityQueue(Item, void, struct {
        fn lessThan(_: void, a: Item, b: Item) std.math.Order {
            return std.math.order(a.cost, b.cost);
        }
    }.lessThan).initContext({});
    defer pq.deinit(gpa);

    var st = State{};
    for (starts, 0..) |_, i| st.robots[i] = n_keys + @as(u8, @intCast(i));
    try pq.push(gpa, .{ .cost = 0, .state = st });

    var visited = Map(u64, void).init(gpa);
    defer visited.deinit();

    while (pq.pop()) |item| {
        const s = item.state;
        if (s.mask == all_keys) return item.cost;
        var h = std.hash.Wyhash.init(0);
        h.update(&s.robots);
        h.update(std.mem.asBytes(&s.mask));
        const key = h.final();
        if (visited.contains(key)) continue;
        try visited.put(key, {});

        for (0..R) |r| {
            const u = s.robots[r];
            for (adj[u].items) |e| {
                if (s.mask & keyBit(e.to) != 0) continue; // already have
                if (e.doors & ~s.mask != 0) continue; // locked
                var ns = s;
                ns.robots[r] = e.to;
                ns.mask |= keyBit(e.to);
                try pq.push(gpa, .{ .cost = item.cost + e.dist, .state = ns });
            }
        }
    }
    return error.NoSolution;
}

pub fn main() !void {
    // parse
    var grid: [gh][gw]u8 = @splat(@splat('#'));
    var w: usize = 0;
    var h: usize = 0;
    var n_keys: u8 = 0;
    var start: P = .{ .x = 0, .y = 0 };
    {
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            @memcpy(grid[h][0..line.len], line);
            w = @max(w, line.len);
            for (line, 0..) |c, x| {
                if (c == '@') start = .{ .x = x, .y = h };
                if (c >= 'a' and c <= 'z') n_keys += 1;
            }
            h += 1;
        }
    }

    // part 1: single robot
    {
        var starts = [_]P{start};
        const steps = try solve(grid, starts[0..1], n_keys);
        print("part 1: {d}\n", .{steps});
    }

    // part 2: split into four quadrants
    {
        var g2 = grid;
        const x = start.x;
        const y = start.y;
        g2[y - 1][x - 1] = '@';
        g2[y - 1][x] = '#';
        g2[y - 1][x + 1] = '@';
        g2[y][x - 1] = '#';
        g2[y][x] = '#';
        g2[y][x + 1] = '#';
        g2[y + 1][x - 1] = '@';
        g2[y + 1][x] = '#';
        g2[y + 1][x + 1] = '@';
        var starts = [_]P{
            .{ .x = x - 1, .y = y - 1 },
            .{ .x = x + 1, .y = y - 1 },
            .{ .x = x - 1, .y = y + 1 },
            .{ .x = x + 1, .y = y + 1 },
        };
        const steps = try solve(g2, starts[0..4], n_keys);
        print("part 2: {d}\n", .{steps});
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
