const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day16.txt");

const Valve = struct {
    name: []const u8,
    flow: u32,
    tunnels: List([]const u8) = .empty,
};

var valves: List(Valve) = .empty;
var index_of = StrMap(usize).init(std.heap.page_allocator);
var dist: [64][64]i32 = undefined; // BFS distances between useful valves

/// Upper bound on additional release: every still-closed valve opened
/// instantly for the remaining time (precomputed suffix max flows).
fn boundRemaining(opened_mask: u32, time_left: i32) u32 {
    var bound: u32 = 0;
    var v: usize = 0;
    while (v < useful_count) : (v += 1) {
        if (opened_mask & (@as(u32, 1) << @intCast(v)) == 0) {
            const f = valveFlow(v);
            // sum over all open valves is a valid (loose) bound
            bound += f * @as(u32, @intCast(@max(time_left, 0)));
        }
    }
    return bound;
}

/// DFS over opened-valve subsets; returns the best release.
fn search(from: usize, time_left: i32, opened: *Map(u32, void), flow_so_far: u32, best: *u32) !void {
    if (flow_so_far > best.*) best.* = flow_so_far;
    var opened_mask: u32 = 0;
    var kit = opened.keyIterator();
    while (kit.next()) |k| opened_mask |= k.*;
    if (flow_so_far + boundRemaining(opened_mask, time_left) <= best.*) return;
    const useful = useful_count;
    for (0..useful) |v| {
        const bit = @as(u32, 1) << @intCast(v);
        if (opened.contains(bit)) continue;
        const t = time_left - dist[from][v] - 1;
        if (t <= 0) continue;
        try opened.put(bit, {});
        const gain = @as(u32, @intCast(t)) * valveFlow(v);
        try search(v, t, opened, flow_so_far + gain, best);
        _ = opened.remove(bit);
    }
}

var useful_ids: [64]usize = undefined;
var useful_count: usize = 0;

fn valveFlow(useful_idx: usize) u32 {
    return valves.items[useful_ids[useful_idx]].flow;
}

pub fn main() !void {
    // parse
    {
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            // "Valve AA has flow rate=0; tunnels lead to valves DD, II, BB"
            const semi = indexOf(u8, line, ';').?;
            const flow = try parseInt(u32, line[23..semi], 10);
            const name = try std.heap.page_allocator.dupe(u8, line[6..8]);
            try index_of.put(name, valves.items.len);
            try valves.append(gpa, .{ .name = name, .flow = flow });
            const rest = line[semi + 1 ..];
            // "tunnels lead to valves X, Y" OR singular "tunnel leads to valve X"
            const v_at = std.mem.indexOf(u8, rest, "valve").?;
            var names = rest[v_at + "valve".len ..];
            if (names.len > 0 and names[0] == 's') names = names[1..];
            names = trim(u8, names, " ");
            var it = tokenizeAny(u8, names, ", ");
            const vi = valves.items.len - 1;
            while (it.next()) |t| {
                try valves.items[vi].tunnels.append(gpa, t);
            }
        }
    }

    const n = valves.items.len;
    const aa = index_of.get("AA").?;

    // useful valves (flow > 0), AA included for distance purposes
    useful_count = 0;
    for (valves.items, 0..) |v, i| {
        if (v.flow > 0) {
            useful_ids[useful_count] = i;
            useful_count += 1;
        }
    }

    // BFS distances from each useful valve (and AA) to all valves
    // dist[u][v]: between useful index u and useful index v; dist[useful_count] = AA
    var sources: [65]usize = undefined;
    for (0..useful_count) |u| sources[u] = useful_ids[u];
    sources[useful_count] = aa;

    for (0..useful_count + 1) |s| {
        // BFS from sources[s]
        var d = try gpa.alloc(i32, n);
        defer gpa.free(d);
        @memset(d, -1);
        d[sources[s]] = 0;
        var q: List(usize) = .empty;
        defer q.deinit(gpa);
        try q.append(gpa, sources[s]);
        var head: usize = 0;
        while (head < q.items.len) : (head += 1) {
            const cur = q.items[head];
            for (valves.items[cur].tunnels.items) |t| {
                const ti = index_of.get(t).?;
                if (d[ti] == -1) {
                    d[ti] = d[cur] + 1;
                    try q.append(gpa, ti);
                }
            }
        }
        for (0..useful_count) |u| {
            dist[s][u] = d[useful_ids[u]];
        }
    }

    // part 1: 30 minutes from AA (source index = useful_count)
    {
        var opened = Map(u32, void).init(gpa);
        defer opened.deinit();
        var best: u32 = 0;
        try search(useful_count, 30, &opened, 0, &best);
        print("part 1: {d}\n", .{best});
    }

    // part 2: 26 minutes, me + elephant — enumerate subsets: I take S, elephant takes ~S
    {
        // best over subsets: compute best release for each achievable subset
        // via full search tracking mask
        var best_for = Map(u32, u32).init(gpa);
        defer best_for.deinit();
        var opened = Map(u32, void).init(gpa);
        defer opened.deinit();
        try searchMasks(useful_count, 26, &opened, 0, 0, &best_for);

        // pair any two disjoint masks (valves may be left unopened)
        var list: List(struct { m: u32, f: u32 }) = .empty;
        defer list.deinit(gpa);
        var mit = best_for.iterator();
        while (mit.next()) |e| {
            try list.append(gpa, .{ .m = e.key_ptr.*, .f = e.value_ptr.* });
        }
        var best: u32 = 0;
        for (list.items) |a| {
            for (list.items) |b| {
                if (a.m & b.m == 0) {
                    best = @max(best, a.f + b.f);
                }
            }
        }
        print("part 2: {d}\n", .{best});
    }
}

/// Like search but records the best flow per exact opened-mask.
fn searchMasks(from: usize, time_left: i32, opened: *Map(u32, void), flow_so_far: u32, mask: u32, best_for: *Map(u32, u32)) anyerror!void {
    const gop = try best_for.getOrPut(mask);
    if (!gop.found_existing or flow_so_far > gop.value_ptr.*) {
        gop.value_ptr.* = flow_so_far;
    }
    // prune: cannot beat the best split already found for the complement
    const total_mask = (@as(u32, 1) << @intCast(useful_count)) - 1;
    if (best_for.get(mask ^ total_mask)) |c| {
        _ = c; // complement flow is a lower bound for the other actor; not a
        // prune condition by itself — skip pruning here, mask dedup above is
        // the main win
    }
    for (0..useful_count) |v| {
        const bit = @as(u32, 1) << @intCast(v);
        if (mask & bit != 0) continue;
        const t = time_left - dist[from][v] - 1;
        if (t <= 0) continue;
        const gain = @as(u32, @intCast(t)) * valveFlow(v);
        try searchMasks(v, t, opened, flow_so_far + gain, mask | bit, best_for);
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
