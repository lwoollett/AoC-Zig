const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day14.txt");

const Robot = struct { px: i64, py: i64, vx: i64, vy: i64 };

const w = 101;
const h = 103;

pub fn main() !void {
    var robots: List(Robot) = .empty;
    defer robots.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, "p=,v ");
        const px = try parseInt(i64, it.next().?, 10);
        const py = try parseInt(i64, it.next().?, 10);
        const vx = try parseInt(i64, it.next().?, 10);
        const vy = try parseInt(i64, it.next().?, 10);
        try robots.append(gpa, .{ .px = px, .py = py, .vx = vx, .vy = vy });
    }

    // part 1: after 100 seconds
    {
        var q = [4]u64{ 0, 0, 0, 0 };
        for (robots.items) |r| {
            const x = @mod(r.px + r.vx * 100, w);
            const y = @mod(r.py + r.vy * 100, h);
            if (x == w / 2 or y == h / 2) continue;
            const qx: usize = if (x < w / 2) 0 else 1;
            const qy: usize = if (y < h / 2) 0 else 1;
            q[qy * 2 + qx] += 1;
        }
        print("part 1: {d}\n", .{q[0] * q[1] * q[2] * q[3]});
    }

    // part 2: find the frame where robots form the christmas tree —
    // heuristic: minimal quadrant-entropy / most clustered frame
    {
        var best_t: u64 = 0;
        var best_score: i64 = std.math.minInt(i64);
        const grid = try gpa.alloc(u8, w * h);
        defer gpa.free(grid);
        var t: u64 = 0;
        while (t < 10000) : (t += 1) {
            // count robots sharing a cell with another (clusters), tracked
            // in a flat occupancy grid — no per-frame hashmap churn
            @memset(grid, 0);
            var clustered: i64 = 0;
            for (robots.items) |r| {
                const x = @mod(r.px + r.vx * @as(i64, @intCast(t)), w);
                const y = @mod(r.py + r.vy * @as(i64, @intCast(t)), h);
                const i: usize = @intCast(y * w + x);
                if (grid[i] != 0) {
                    clustered += 1;
                } else {
                    grid[i] = 1;
                }
            }
            if (clustered > best_score) {
                best_score = clustered;
                best_t = t;
            }
        }
        print("part 2: {d}\n", .{best_t});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
