const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day25.txt");

var names = StrMap(usize).init(std.heap.page_allocator);
var adj: List(List(usize)) = .empty; // multigraph adjacency (parallel edges allowed)

fn nodeOf(name: []const u8) !usize {
    const gop = try names.getOrPut(name);
    if (!gop.found_existing) {
        gop.value_ptr.* = adj.items.len;
        try adj.append(gpa, .empty);
    }
    return gop.value_ptr.*;
}

/// Stoer-Wagner minimum cut over a dense weight matrix.
fn stoerWagner() !u64 {
    const n = adj.items.len;

    // dense weight matrix
    var wmat = try gpa.alloc([]i32, n);
    defer {
        for (wmat) |r| gpa.free(r);
        gpa.free(wmat);
    }
    for (wmat) |*r| {
        r.* = try gpa.alloc(i32, n);
        @memset(r.*, 0);
    }
    for (adj.items, 0..) |nbrs, u| {
        for (nbrs.items) |v| {
            wmat[u][v] += 1;
        }
    }

    // group membership: group[i] = list of original nodes merged into super-node i
    var groups = try gpa.alloc(List(usize), n);
    defer {
        for (groups) |*g| g.deinit(gpa);
        gpa.free(groups);
    }
    for (0..n) |i| {
        groups[i] = .empty;
        try groups[i].append(gpa, i);
    }

    var active = try gpa.alloc(bool, n);
    defer gpa.free(active);
    @memset(active, true);

    var best: i32 = std.math.maxInt(i32);
    var best_group: List(usize) = .empty;
    defer best_group.deinit(gpa);

    var phase: usize = 0;
    while (phase < n - 1) : (phase += 1) {
        // count of active nodes
        var count: usize = 0;
        for (active) |a| {
            if (a) count += 1;
        }
        if (count <= 1) break;

        // minimum cut phase: Prim-like maximum adjacency search
        var in_a = try gpa.alloc(bool, n);
        defer gpa.free(in_a);
        @memset(in_a, false);

        var weights = try gpa.alloc(i32, n);
        defer gpa.free(weights);
        @memset(weights, 0);

        // start from any active node
        var start: usize = 0;
        for (0..n) |i| {
            if (active[i]) {
                start = i;
                break;
            }
        }
        in_a[start] = true;

        var last: usize = start;
        var prev: usize = start;
        var added: usize = 1;
        while (added < count) {
            // add the most tightly connected vertex
            var best_v: usize = 0;
            var best_w: i32 = -1;
            for (0..n) |v| {
                if (!active[v] or in_a[v]) continue;
                weights[v] += wmat[last][v];
                if (weights[v] > best_w) {
                    best_w = weights[v];
                    best_v = v;
                }
            }
            in_a[best_v] = true;
            prev = last;
            last = best_v;
            added += 1;
        }

        const cut_of_phase = weights[last];
        if (cut_of_phase < best) {
            best = cut_of_phase;
            best_group.clearRetainingCapacity();
            try best_group.appendSlice(gpa, groups[last].items);
        }

        // merge `last` into `prev`
        for (0..n) |v| {
            if (!active[v] or v == prev or v == last) continue;
            wmat[prev][v] += wmat[last][v];
            wmat[v][prev] = wmat[prev][v];
        }
        try groups[prev].appendSlice(gpa, groups[last].items);
        groups[last].clearRetainingCapacity();
        active[last] = false;
    }

    const size_a: u64 = best_group.items.len;
    const size_b: u64 = @intCast(n - size_a);
    return size_a * size_b;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const colon = indexOf(u8, line, ':').?;
        const a = try nodeOf(try std.heap.page_allocator.dupe(u8, line[0..colon]));
        var it = tokenizeSca(u8, line[colon + 1 ..], ' ');
        while (it.next()) |tok| {
            const b = try nodeOf(try std.heap.page_allocator.dupe(u8, tok));
            try adj.items[a].append(gpa, b);
            try adj.items[b].append(gpa, a);
        }
    }

    print("part 1: {d}\n", .{try stoerWagner()});
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
