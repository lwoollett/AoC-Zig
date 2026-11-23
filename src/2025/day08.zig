const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

const data = @embedFile("data/day08.txt");

const P = [3]i64;

const Pair = struct { d: u64, i: usize, j: usize };

var parent: List(usize) = .empty;

fn find(x: usize) usize {
    if (parent.items[x] == x) return x;
    parent.items[x] = find(parent.items[x]);
    return parent.items[x];
}

fn unionBoxes(a: usize, b: usize) void {
    const ra = find(a);
    const rb = find(b);
    if (ra != rb) {
        parent.items[ra] = rb;
    }
}

pub fn main() !void {
    var pts: List(P) = .empty;
    defer pts.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeSca(u8, line, ',');
        const x = try parseInt(i64, it.next().?, 10);
        const y = try parseInt(i64, it.next().?, 10);
        const z = try parseInt(i64, it.next().?, 10);
        try pts.append(gpa, .{ x, y, z });
    }
    const n = pts.items.len;

    for (0..n) |i| {
        try parent.append(gpa, i);
    }

    // all pairs by squared distance
    var pairs: List(Pair) = .empty;
    defer pairs.deinit(gpa);
    for (pts.items, 0..) |a, i| {
        for (pts.items[i + 1 ..], i + 1..) |b, j| {
            const dx = a[0] - b[0];
            const dy = a[1] - b[1];
            const dz = a[2] - b[2];
            const d2: u64 = @intCast(dx * dx + dy * dy + dz * dz);
            try pairs.append(gpa, .{ .d = d2, .i = i, .j = j });
        }
    }
    std.mem.sort(Pair, pairs.items, {}, struct {
        fn lessThan(_: void, a: Pair, b: Pair) bool {
            if (a.d != b.d) return a.d < b.d;
            if (a.i != b.i) return a.i < b.i;
            return a.j < b.j;
        }
    }.lessThan);

    // connect the 1000 closest
    var connected: usize = 0;
    for (pairs.items) |p| {
        if (connected >= 1000) break;
        unionBoxes(p.i, p.j);
        connected += 1;
    }

    // component sizes
    var size = try gpa.alloc(u64, n);
    defer gpa.free(size);
    @memset(size, 0);
    for (0..n) |i| {
        size[find(i)] += 1;
    }
    var top: [3]u64 = .{ 0, 0, 0 };
    for (size) |s| {
        if (s > top[0]) {
            top[2] = top[1];
            top[1] = top[0];
            top[0] = s;
        } else if (s > top[1]) {
            top[2] = top[1];
            top[1] = s;
        } else if (s > top[2]) {
            top[2] = s;
        }
    }
    print("part 1: {d}\n", .{top[0] * top[1] * top[2]});

    // part 2: continue the single-linkage (connect closest cross-circuit
    // pair until one circuit); answer = product of X coords of the last pair.
    // Part 1 already merged the 1000 closest pairs — resume from there.
    {
        var remaining: usize = 0;
        {
            var roots = std.AutoHashMap(usize, void).init(gpa);
            defer roots.deinit();
            for (0..n) |k| {
                const r = find(k);
                if (!roots.contains(r)) {
                    try roots.put(r, {});
                    remaining += 1;
                }
            }
        }
        for (pairs.items) |pr| {
            const ra = find(pr.i);
            const rb = find(pr.j);
            if (ra == rb) continue;
            parent.items[ra] = rb;
            remaining -= 1;
            if (remaining == 1) {
                print("part 2: {d}\n", .{pts.items[pr.i][0] * pts.items[pr.j][0]});
                return;
            }
        }
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSca = std.mem.tokenizeScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
