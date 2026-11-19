const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day23.txt");

var grid: [200][200]u8 = @splat(@splat('#'));
var h: usize = 0;
var w: usize = 0;

const Node = [2]usize;
const Edge = struct { to: usize, len: usize };

var nodes: List(Node) = .empty;
var edges: List(List(Edge)) = .empty;

fn isJunction(x: usize, y: usize, comptime slopes: bool) bool {
    if (grid[y][x] == '#') return false;
    var open: u32 = 0;
    const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
    for (deltas) |d| {
        const nx = @as(i64, @intCast(x)) + d[0];
        const ny = @as(i64, @intCast(y)) + d[1];
        if (nx < 0 or ny < 0 or nx >= w or ny >= h) continue;
        if (grid[@intCast(ny)][@intCast(nx)] != '#') open += 1;
    }
    _ = slopes;
    return open >= 3 or (y == 0) or (y == h - 1);
}

/// walk from junction node `from` in direction (dx,dy) until the next junction
fn trace(from: usize, dx0: i64, dy0: i64, comptime slopes: bool) ?struct { to: Node, len: usize } {
    var x = nodes.items[from][0];
    var y = nodes.items[from][1];
    var px: usize = x;
    var py: usize = y;
    const fx = @as(i64, @intCast(x)) + dx0;
    const fy = @as(i64, @intCast(y)) + dy0;
    if (fx < 0 or fy < 0 or fx >= w or fy >= h) return null;
    x = @intCast(fx);
    y = @intCast(fy);
    if (grid[y][x] == '#') return null;
    var len: usize = 0;
    const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
    while (true) {
        len += 1;
        if (isJunction(x, y, slopes)) {
            return .{ .to = .{ x, y }, .len = len };
        }
        var nx: usize = x;
        var ny: usize = y;
        var moved = false;
        for (deltas) |d| {
            const tx = @as(i64, @intCast(x)) + d[0];
            const ty = @as(i64, @intCast(y)) + d[1];
            if (tx < 0 or ty < 0 or tx >= w or ty >= h) continue;
            const txu: usize = @intCast(tx);
            const tyu: usize = @intCast(ty);
            if (txu == px and tyu == py) continue; // don't backtrack
            const c = grid[tyu][txu];
            if (c == '#') continue;
            if (slopes) {
                const ok = switch (c) {
                    '^' => d[1] == -1,
                    'v' => d[1] == 1,
                    '<' => d[0] == -1,
                    '>' => d[0] == 1,
                    else => true,
                };
                if (!ok) continue;
            }
            nx = txu;
            ny = tyu;
            moved = true;
            break;
        }
        if (!moved) return null;
        px = x;
        py = y;
        x = nx;
        y = ny;
    }
}

var node_index = Map(Node, usize).init(std.heap.page_allocator);

fn buildGraph(comptime slopes: bool) !void {
    nodes.clearRetainingCapacity();
    node_index.clearRetainingCapacity();
    edges.clearRetainingCapacity();
    for (0..h) |y| {
        for (0..w) |x| {
            if (isJunction(x, y, slopes)) {
                try node_index.put(.{ x, y }, nodes.items.len);
                try nodes.append(gpa, .{ x, y });
                try edges.append(gpa, .empty);
            }
        }
    }
    for (0..nodes.items.len) |i| {
        const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
        for (deltas) |d| {
            if (trace(i, d[0], d[1], slopes)) |r| {
                const j = node_index.get(r.to).?;
                try edges.items[i].append(gpa, .{ .to = j, .len = r.len });
            }
        }
    }
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }
    grid[0][1] = 'S'; // mark start visually (it's a junction anyway)

    // identify start/end node indices: start = top junction, end = bottom
    // start node has y == 0; end has y == h-1

    // part 1: slope-aware graph, plain DFS (small search)
    try buildGraph(true);
    const se1 = findStartEnd();
    const e1 = try snapshotEdges();
    var c1 = DfsCtx{ .edges = e1, .end_i = se1[1] };
    dfsMask(&c1, se1[0], 0, 0);
    print("part 1: {d}\n", .{c1.best});

    // part 2: no slopes — the search is all-path enumeration, so split it
    // across threads at a small frontier of partial paths
    try buildGraph(false);
    const se2 = findStartEnd();
    const e2 = try snapshotEdges();
    const best2 = try parallelLongest(e2, se2[0], se2[1]);
    print("part 2: {d}\n", .{best2});
}

/// Enumerate partial paths from `start` until the frontier is wide enough,
/// then DFS each frontier item on a thread pool. Independent searches share
/// nothing, so it scales linearly (each thread prunes only against its own
/// best).
fn parallelLongest(graph: []const []const Edge, start: usize, end_i: usize) !usize {
    const FrItem = struct { node: usize, dist: usize, mask: u64 };
    var frontier: List(FrItem) = .empty;
    defer frontier.deinit(gpa);
    try frontier.append(gpa, .{ .node = start, .dist = 0, .mask = 0 });

    const n_threads = try std.Thread.getCpuCount();
    var depth: usize = 0;
    while (depth < 10 and frontier.items.len < n_threads * 2) : (depth += 1) {
        var next: List(FrItem) = .empty;
        for (frontier.items) |it| {
            const bit = @as(u64, 1) << @intCast(it.node);
            for (graph[it.node]) |e| {
                if (it.mask & bit != 0) continue; // node already on this path
                if (it.mask & (@as(u64, 1) << @intCast(e.to)) != 0) continue;
                try next.append(gpa, .{ .node = e.to, .dist = it.dist + e.len, .mask = it.mask | bit });
            }
        }
        if (next.items.len == 0) break;
        frontier.deinit(gpa);
        frontier = next;
    }

    const W = struct {
        edges: []const []const Edge,
        end_i: usize,
        items: []const FrItem,
        next: std.atomic.Value(u64) = .init(0),
        best: std.atomic.Value(usize) = .init(0),

        fn worker(self: *@This()) void {
            var local: usize = 0;
            while (true) {
                const i = self.next.fetchAdd(1, .acq_rel);
                if (i >= self.items.len) break;
                var c = DfsCtx{ .edges = self.edges, .end_i = self.end_i };
                dfsMask(&c, self.items[i].node, self.items[i].dist, self.items[i].mask);
                local = @max(local, c.best);
            }
            _ = self.best.fetchMax(local, .acq_rel);
        }
    };
    var work = W{ .edges = graph, .end_i = end_i, .items = frontier.items };
    var threads = try std.ArrayList(std.Thread).initCapacity(gpa, n_threads);
    defer threads.deinit(gpa);
    for (0..n_threads) |_| {
        try threads.append(gpa, try std.Thread.spawn(.{}, W.worker, .{&work}));
    }
    for (threads.items) |t| t.join();
    return work.best.load(.acquire);
}

fn findStartEnd() [2]usize {
    var se: [2]usize = .{ 0, 0 };
    for (nodes.items, 0..) |n, i| {
        if (n[1] == 0) se[0] = i;
        if (n[1] == h - 1) se[1] = i;
    }
    return se;
}

fn snapshotEdges() ![]const []const Edge {
    const out = try gpa.alloc([]const Edge, edges.items.len);
    for (edges.items, 0..) |l, i| {
        out[i] = try gpa.dupe(Edge, l.items);
    }
    return out;
}

const DfsCtx = struct {
    edges: []const []const Edge,
    best: usize = 0,
    end_i: usize,
};

/// Longest simple path via DFS; `mask` is the on-path set (nodes <= 64).
fn dfsMask(c: *DfsCtx, node: usize, dist: usize, mask: u64) void {
    if (node == c.end_i) {
        c.best = @max(c.best, dist);
        return;
    }
    const bit = @as(u64, 1) << @intCast(node);
    if (mask & bit != 0) return;
    for (c.edges[node]) |e| {
        dfsMask(c, e.to, dist + e.len, mask | bit);
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
