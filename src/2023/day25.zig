const std = @import("std");
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day25.txt");

var names = StrMap(usize).init(std.heap.page_allocator);
var adj: List(List(usize)) = .empty; // neighbor lists (parallel edges allowed)

fn nodeOf(name: []const u8) !usize {
    const gop = try names.getOrPut(name);
    if (!gop.found_existing) {
        gop.value_ptr.* = adj.items.len;
        try adj.append(gpa, .empty);
    }
    return gop.value_ptr.*;
}

/// Stoer-Wagner min cut over a sparse multigraph: parallel edges stay
/// separate (weight 1 each), so a supernode's cut is just its edge count.
/// Each maximum-adjacency visit uses a lazy bucket queue — keys only rise,
/// extracts are amortized O(1) — for O(n+m) phases -> O(n*(n+m)) total.
fn stoerWagner() !u64 {
    const n = adj.items.len;

    // dedup edge list (adj stores each edge twice)
    var eu: List(usize) = .empty;
    defer eu.deinit(gpa);
    var ev: List(usize) = .empty;
    defer ev.deinit(gpa);
    var inc = try gpa.alloc(List(usize), n);
    defer {
        for (inc) |*l| l.deinit(gpa);
        gpa.free(inc);
    }
    for (inc) |*l| l.* = .empty;
    for (adj.items, 0..) |nbrs, u| {
        for (nbrs.items) |v| {
            if (v <= u) continue;
            const eid = eu.items.len;
            try eu.append(gpa, u);
            try ev.append(gpa, v);
            try inc[u].append(gpa, eid);
            try inc[v].append(gpa, eid);
        }
    }
    const m = eu.items.len;

    var edge_alive = try gpa.alloc(bool, m);
    defer gpa.free(edge_alive);
    @memset(edge_alive, true);
    var alive = try gpa.alloc(bool, n);
    defer gpa.free(alive);
    @memset(alive, true);
    var size = try gpa.alloc(u64, n);
    defer gpa.free(size);
    @memset(size, 1);

    var key = try gpa.alloc(i64, n);
    defer gpa.free(key);
    var extracted = try gpa.alloc(usize, n); // phase stamp
    defer gpa.free(extracted);
    @memset(extracted, 0);
    var buckets = try gpa.alloc(List(usize), m + 2);
    defer {
        for (buckets) |*b| b.deinit(gpa);
        gpa.free(buckets);
    }
    for (buckets) |*b| b.* = .empty;

    var touched: List(usize) = .empty;
    defer touched.deinit(gpa);

    var best: i64 = std.math.maxInt(i64);
    var best_size: u64 = 0;
    var n_alive = n;
    var phase: usize = 0;

    while (n_alive > 1) {
        phase += 1;
        // seed: all alive nodes at key 0
        @memset(key[0..n], 0);
        for (0..n) |v| {
            if (alive[v]) try buckets[0].append(gpa, v);
        }
        var max_hint: usize = 0;
        var last: usize = 0;
        var prev: usize = 0;
        var extracted_count: usize = 0;

        while (extracted_count < n_alive) {
            while (buckets[max_hint].items.len > 0) {
                const v = buckets[max_hint].pop().?;
                if (!alive[v] or extracted[v] == phase or key[v] != max_hint) continue; // stale
                // extract v
                extracted[v] = phase;
                prev = last;
                last = v;
                extracted_count += 1;
                for (inc[v].items) |e| {
                    if (!edge_alive[e]) continue;
                    const w = if (eu.items[e] == v) ev.items[e] else eu.items[e];
                    if (!alive[w] or extracted[w] == phase) continue;
                    key[w] += 1;
                    if (key[w] > max_hint) max_hint = @intCast(key[w]);
                    try buckets[@intCast(key[w])].append(gpa, w);
                    try touched.append(gpa, @intCast(key[w]));
                }
                break;
            }
            if (extracted_count < n_alive and buckets[max_hint].items.len == 0) {
                if (max_hint == 0) unreachable; // every alive node was seeded
                max_hint -= 1;
            }
        }

        const cut: i64 = key[last];
        if (cut < best) {
            best = cut;
            best_size = size[last];
        }

        // merge last into prev
        alive[last] = false;
        n_alive -= 1;
        size[prev] += size[last];
        for (inc[last].items) |e| {
            if (!edge_alive[e]) continue;
            const w = if (eu.items[e] == last) ev.items[e] else eu.items[e];
            if (w == prev) {
                edge_alive[e] = false; // self loop after merge
                continue;
            }
            if (eu.items[e] == last) eu.items[e] = prev else ev.items[e] = prev;
            try inc[prev].append(gpa, e);
        }
        inc[last].clearAndFree(gpa);

        // clear the buckets this phase touched (entries are stale next phase)
        for (touched.items) |b| buckets[b].clearRetainingCapacity();
        touched.clearRetainingCapacity();
    }

    return best_size * (n - best_size);
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
const tokenizeSca = std.mem.tokenizeScalar;
const indexOf = std.mem.findScalar;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
