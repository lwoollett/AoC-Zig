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

var grid: [200][200]u8 = @splat(@splat('#'));
var h: usize = 0;
var w: usize = 0;

const Node = [2]usize;

var nodes: List(Node) = .empty;
var edges: List(List(struct { to: usize, len: usize })) = .empty;

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

var best_dist: usize = 0;
var visited: List(bool) = .empty;

fn dfs(node: usize, dist: usize) void {
    if (node == 1) { // end node (second junction created — the bottom exit)
        best_dist = @max(best_dist, dist);
        return;
    }
    if (visited.items[node]) return;
    visited.items[node] = true;
    for (edges.items[node].items) |e| {
        dfs(e.to, dist + e.len);
    }
    visited.items[node] = false;
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

    // part 1
    {
        try buildGraph(true);
        // find start (y==0) and end (y==h-1)
        var start_i: usize = 0;
        var end_i: usize = 0;
        for (nodes.items, 0..) |n, i| {
            if (n[1] == 0) start_i = i;
            if (n[1] == h - 1) end_i = i;
        }
        best_dist = 0;
        visited.clearRetainingCapacity();
        for (0..nodes.items.len) |_| try visited.append(gpa, false);
        // dfs with end check
        dfsGeneric(start_i, end_i, 0);
        print("part 1: {d}\n", .{best_dist});
    }

    // part 2
    {
        try buildGraph(false);
        var start_i: usize = 0;
        var end_i: usize = 0;
        for (nodes.items, 0..) |n, i| {
            if (n[1] == 0) start_i = i;
            if (n[1] == h - 1) end_i = i;
        }
        best_dist = 0;
        visited.clearRetainingCapacity();
        for (0..nodes.items.len) |_| try visited.append(gpa, false);
        dfsGeneric(start_i, end_i, 0);
        print("part 2: {d}\n", .{best_dist});
    }
}

fn dfsGeneric(node: usize, end_i: usize, dist: usize) void {
    if (node == end_i) {
        best_dist = @max(best_dist, dist);
        return;
    }
    if (visited.items[node]) return;
    visited.items[node] = true;
    for (edges.items[node].items) |e| {
        dfsGeneric(e.to, end_i, dist + e.len);
    }
    visited.items[node] = false;
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
