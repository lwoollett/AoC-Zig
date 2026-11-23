const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

const data = @embedFile("data/day09.txt");

const P = [2]i64;

pub fn main() !void {
    var tiles: List(P) = .empty;
    defer tiles.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const comma = indexOf(u8, line, ',').?;
        try tiles.append(gpa, .{
            try parseInt(i64, line[0..comma], 10),
            try parseInt(i64, line[comma + 1 ..], 10),
        });
    }

    // any two red tiles as opposite corners; other tiles may lie inside
    var best: i64 = 0;
    for (tiles.items, 0..) |a, i| {
        for (tiles.items[i + 1 ..]) |b| {
            const w = @as(i64, @intCast(@abs(a[0] - b[0]))) + 1;
            const h = @as(i64, @intCast(@abs(a[1] - b[1]))) + 1;
            best = @max(best, w * h);
        }
    }
    print("part 1: {d}\n", .{best});

    // part 2: green tiles = the closed rectilinear loop through the red
    // tiles (consecutive tiles joined axis-aligned, wrapping) plus its
    // interior. Max-area rectangle with red corners, fully inside the loop.
    // Coordinate compression: the loop's edges make each block between
    // consecutive distinct x's/y's uniformly inside or outside.
    {
        const n = tiles.items.len;
        var xs: List(i64) = .empty;
        defer xs.deinit(gpa);
        var ys: List(i64) = .empty;
        defer ys.deinit(gpa);
        for (tiles.items) |t| {
            try xs.append(gpa, t[0]);
            try ys.append(gpa, t[1]);
        }
        std.mem.sort(i64, xs.items, {}, std.sort.asc(i64));
        std.mem.sort(i64, ys.items, {}, std.sort.asc(i64));
        var xn: usize = 0;
        for (xs.items, 0..) |v, i| {
            if (i == 0 or v != xs.items[i - 1]) {
                xs.items[xn] = v;
                xn += 1;
            }
        }
        xs.shrinkRetainingCapacity(xn);
        var yn: usize = 0;
        for (ys.items, 0..) |v, i| {
            if (i == 0 or v != ys.items[i - 1]) {
                ys.items[yn] = v;
                yn += 1;
            }
        }
        ys.shrinkRetainingCapacity(yn);

        var x_index = std.AutoHashMap(i64, usize).init(gpa);
        defer x_index.deinit();
        var y_index = std.AutoHashMap(i64, usize).init(gpa);
        defer y_index.deinit();
        for (xs.items, 0..) |v, i| try x_index.put(v, i);
        for (ys.items, 0..) |v, i| try y_index.put(v, i);

        // horizontal loop edges (same-row consecutive tiles, wrapping)
        var hys: List(i64) = .empty; // y of each horizontal edge
        defer hys.deinit(gpa);
        var hx0: List(i64) = .empty;
        defer hx0.deinit(gpa);
        var hx1: List(i64) = .empty;
        defer hx1.deinit(gpa);
        for (tiles.items, 0..) |a, k| {
            const b = tiles.items[(k + 1) % n];
            if (a[1] == b[1]) {
                try hys.append(gpa, a[1]);
                try hx0.append(gpa, @min(a[0], b[0]));
                try hx1.append(gpa, @max(a[0], b[0]));
            }
        }

        // mark inside blocks by scanline (even-odd crossings at strip midpoints)
        const bad = try gpa.alloc(u32, xn * yn);
        defer gpa.free(bad);
        for (0..xn - 1) |i| {
            const midx = (@as(f64, @floatFromInt(xs.items[i])) + @as(f64, @floatFromInt(xs.items[i + 1]))) / 2;
            var crossings: List(f64) = .empty;
            defer crossings.deinit(gpa);
            for (hys.items, 0..) |ey, e| {
                const x0f: f64 = @floatFromInt(hx0.items[e]);
                const x1f: f64 = @floatFromInt(hx1.items[e]);
                if (x0f < midx and midx < x1f) {
                    try crossings.append(gpa, @floatFromInt(ey));
                }
            }
            std.mem.sort(f64, crossings.items, {}, std.sort.asc(f64));
            for (0..yn - 1) |j| {
                const midy = (@as(f64, @floatFromInt(ys.items[j])) + @as(f64, @floatFromInt(ys.items[j + 1]))) / 2;
                var in_loop = false;
                var c: usize = 0;
                while (c + 2 <= crossings.items.len) : (c += 2) {
                    if (crossings.items[c] < midy and midy < crossings.items[c + 1]) {
                        in_loop = true;
                        break;
                    }
                }
                bad[i * yn + j] = if (in_loop) 0 else 1;
            }
        }

        // 2D prefix sums of bad blocks
        const pre = try gpa.alloc(u32, (xn + 1) * (yn + 1));
        defer gpa.free(pre);
        @memset(pre, 0);
        for (0..xn - 1) |i| {
            for (0..yn - 1) |j| {
                pre[(i + 1) * (yn + 1) + (j + 1)] =
                    pre[i * (yn + 1) + (j + 1)] + pre[(i + 1) * (yn + 1) + j] -
                    pre[i * (yn + 1) + j] + bad[i * yn + j];
            }
        }

        var best2: i64 = 0;
        for (tiles.items, 0..) |a, ai_| {
            for (tiles.items[ai_ + 1 ..]) |b| {
                const xia = x_index.get(a[0]).?;
                const yia = y_index.get(a[1]).?;
                const xib = x_index.get(b[0]).?;
                const yib = y_index.get(b[1]).?;
                const x0 = @min(xia, xib);
                const x1 = @max(xia, xib);
                const y0 = @min(yia, yib);
                const y1 = @max(yia, yib);
                const sum_bad: i64 = @as(i64, pre[x1 * (yn + 1) + y1]) - @as(i64, pre[x0 * (yn + 1) + y1]) -
                    @as(i64, pre[x1 * (yn + 1) + y0]) + @as(i64, pre[x0 * (yn + 1) + y0]);
                if (sum_bad == 0) {
                    const w = @as(i64, @intCast(@abs(a[0] - b[0]))) + 1;
                    const h2 = @as(i64, @intCast(@abs(a[1] - b[1]))) + 1;
                    best2 = @max(best2, w * h2);
                }
            }
        }
        print("part 2: {d}\n", .{best2});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
