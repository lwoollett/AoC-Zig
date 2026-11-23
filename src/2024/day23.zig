const std = @import("std");
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day23.txt");

var names = StrMap(usize).init(std.heap.page_allocator);
var name_list: List([]const u8) = .empty;

var n: usize = 0;
var words: usize = 0;
var adj: []u64 = &.{}; // n rows x words bitmask adjacency

fn bitTest(row: []const u64, i: usize) bool {
    return row[i >> 6] & (@as(u64, 1) << @intCast(i & 63)) != 0;
}

fn bitSet(row: []u64, i: usize) void {
    row[i >> 6] |= @as(u64, 1) << @intCast(i & 63);
}

fn bitClear(row: []u64, i: usize) void {
    row[i >> 6] &= ~(@as(u64, 1) << @intCast(i & 63));
}

fn andInto(dst: []u64, a: []const u64, b: []const u64) void {
    for (dst, a, b) |*d, x, y| d.* = x & y;
}

fn isEmpty(row: []const u64) bool {
    for (row) |w| {
        if (w != 0) return false;
    }
    return true;
}

fn popcount(row: []const u64) usize {
    var total: usize = 0;
    for (row) |w| total += @popCount(w);
    return total;
}

/// Bron–Kerbosch with Tomita pivoting over bitsets. p/x buffers are pooled
/// per depth; R is the `stack` prefix.
const BK = struct {
    pool_p: [][]u64,
    pool_x: [][]u64,
    pool_c: [][]u64,
    stack: []usize,
    best: []usize,
    best_len: usize = 0,
    tmp: []u64 = &.{},

    fn recurse(self: *BK, p: []u64, x: []u64, depth: usize) void {
        if (isEmpty(p) and isEmpty(x)) {
            if (depth > self.best_len) {
                @memcpy(self.best[0..depth], self.stack[0..depth]);
                self.best_len = depth;
            }
            return;
        }
        // pivot u in P∪X maximizing |N(u) ∩ P|
        var pivot: ?usize = null;
        var pivot_deg: usize = 0;
        for (0..n) |u| {
            const in_px = bitTest(p, u) or bitTest(x, u);
            if (!in_px) continue;
            andInto(self.tmp, adj[u * words ..][0..words], p);
            const d = popcount(self.tmp);
            if (d >= pivot_deg) {
                pivot_deg = d;
                pivot = u;
            }
        }
        // candidates: P \ N(pivot) (snapshot — P mutates as we descend)
        const cand = self.pool_c[depth];
        if (pivot) |u| {
            for (0..words) |w| cand[w] = p[w] & ~adj[u * words + w];
        } else {
            @memcpy(cand[0..words], p[0..words]);
        }
        for (0..words) |w| {
            var m = cand[w];
            while (m != 0) {
                const b: u6 = @intCast(@ctz(m));
                m &= m - 1;
                const v = w * 64 + b;
                if (!bitTest(p, v)) continue; // already moved to X

                self.stack[depth] = v;
                const np = self.pool_p[depth + 1];
                const nx = self.pool_x[depth + 1];
                andInto(np, p, adj[v * words ..][0..words]);
                andInto(nx, x, adj[v * words ..][0..words]);
                self.recurse(np, nx, depth + 1);

                bitClear(p, v);
                bitSet(x, v);
            }
        }
    }
};

fn popcountInto(dst: []u64, a: []const u64, b: []const u64) usize {
    var total: usize = 0;
    for (dst, a, b) |*d, x, y| {
        d.* = x & y;
        total += std.math.popcount(d.*);
    }
    return total;
}

fn nodeName(name: []const u8) !usize {
    const gop = try names.getOrPut(name);
    if (!gop.found_existing) {
        gop.value_ptr.* = name_list.items.len;
        try name_list.append(gpa, name);
    }
    return gop.value_ptr.*;
}

pub fn main() !void {
    var edges: List([2]usize) = .empty;
    defer edges.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const dash = indexOf(u8, line, '-').?;
        const a = try nodeName(line[0..dash]);
        const b = try nodeName(line[dash + 1 ..]);
        try edges.append(gpa, .{ a, b });
    }
    n = name_list.items.len;
    words = (n + 63) / 64;
    adj = try gpa.alloc(u64, n * words);
    defer gpa.free(adj);
    @memset(adj, 0);
    for (edges.items) |e| {
        bitSet(adj[e[0] * words ..][0..words], e[1]);
        bitSet(adj[e[1] * words ..][0..words], e[0]);
    }

    // part 1: triangles containing at least one 't' node
    const t_mask = try gpa.alloc(u64, words);
    defer gpa.free(t_mask);
    @memset(t_mask, 0);
    for (name_list.items, 0..) |nm, i| {
        if (nm[0] == 't') bitSet(t_mask, i);
    }
    var tri: u64 = 0;
    const and_buf = try gpa.alloc(u64, words);
    defer gpa.free(and_buf);
    for (0..n) |a| {
        for (a + 1..n) |b| {
            if (!bitTest(adj[a * words ..][0..words], b)) continue;
            andInto(and_buf, adj[a * words ..][0..words], adj[b * words ..][0..words]);
            // only count c > b
            for (0..words) |w| {
                var m = and_buf[w];
                if (w == b / 64) {
                    // clear bits <= b within this word
                    const keep: u64 = if ((b & 63) == 63) 0 else ~((@as(u64, 1) << @intCast((b & 63) + 1)) - 1);
                    m &= keep;
                } else if (w < b / 64) {
                    m = 0;
                }
                while (m != 0) {
                    const bit: u6 = @intCast(@ctz(m));
                    m &= m - 1;
                    const c = w * 64 + bit;
                    const has_t = bitTest(t_mask, a) or bitTest(t_mask, b) or bitTest(t_mask, c);
                    if (has_t) tri += 1;
                }
            }
        }
    }
    print("part 1: {d}\n", .{tri});

    // part 2: maximum clique
    const max_depth = 64;
    var bk = BK{
        .pool_p = try gpa.alloc([]u64, max_depth),
        .pool_x = try gpa.alloc([]u64, max_depth),
        .pool_c = try gpa.alloc([]u64, max_depth),
        .stack = try gpa.alloc(usize, max_depth),
        .best = try gpa.alloc(usize, max_depth),
        .tmp = try gpa.alloc(u64, words),
    };
    @memset(bk.tmp, 0);
    defer {
        gpa.free(bk.pool_p);
        gpa.free(bk.pool_x);
        gpa.free(bk.pool_c);
        gpa.free(bk.stack);
        gpa.free(bk.best);
        gpa.free(bk.tmp);
    }
    for (0..max_depth) |i| {
        bk.pool_p[i] = try gpa.alloc(u64, words);
        bk.pool_x[i] = try gpa.alloc(u64, words);
        bk.pool_c[i] = try gpa.alloc(u64, words);
        @memset(bk.pool_p[i], 0);
        @memset(bk.pool_x[i], 0);
        @memset(bk.pool_c[i], 0);
    }
    defer for (0..max_depth) |i| {
        gpa.free(bk.pool_p[i]);
        gpa.free(bk.pool_x[i]);
        gpa.free(bk.pool_c[i]);
    };
    const p = try gpa.alloc(u64, words);
    defer gpa.free(p);
    const x = try gpa.alloc(u64, words);
    defer gpa.free(x);
    @memset(p, 0);
    for (0..n) |i| bitSet(p, i);
    @memset(x, 0);
    bk.recurse(p, x, 0);

    var members: List([]const u8) = .empty;
    defer members.deinit(gpa);
    for (bk.best[0..bk.best_len]) |i| {
        try members.append(gpa, name_list.items[i]);
    }
    std.mem.sort([]const u8, members.items, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.order(u8, a, b) == .lt;
        }
    }.lessThan);
    print("part 2: ", .{});
    for (members.items, 0..) |m, i| {
        if (i > 0) print(",", .{});
        print("{s}", .{m});
    }
    print("\n", .{});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
