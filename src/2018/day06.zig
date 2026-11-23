const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day06.txt");

const max_pts = 64;

pub fn main() !void {
    var xs: [max_pts]i32 = undefined;
    var ys: [max_pts]i32 = undefined;
    var n: usize = 0;
    var min_x: i32 = 1 << 30;
    var max_x: i32 = -(1 << 30);
    var min_y: i32 = 1 << 30;
    var max_y: i32 = -(1 << 30);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const comma = std.mem.findScalar(u8, line, ',').?;
        xs[n] = try parseInt(i32, line[0..comma], 10);
        ys[n] = try parseInt(i32, trim(u8, line[comma + 1 ..], " \r"), 10);
        min_x = @min(min_x, xs[n]);
        max_x = @max(max_x, xs[n]);
        min_y = @min(min_y, ys[n]);
        max_y = @max(max_y, ys[n]);
        n += 1;
    }

    // A point whose nearest-claim touches the grid border is infinite.
    // Work on an expanded grid with a margin.
    const margin = 1;
    const w = @as(usize, @intCast(max_x - min_x + 1 + 2 * margin));
    const h = @as(usize, @intCast(max_y - min_y + 1 + 2 * margin));

    var areas: [max_pts]u64 = @splat(0);
    var infinite: [max_pts]bool = @splat(false);
    var region: u64 = 0;

    for (0..h) |gy| {
        for (0..w) |gx| {
            const px: i32 = @as(i32, @intCast(gx)) + min_x - margin;
            const py: i32 = @as(i32, @intCast(gy)) + min_y - margin;
            var best_d: i64 = 1 << 30;
            var best_i: usize = max_pts;
            var tie = false;
            var total: i64 = 0;
            for (0..n) |i| {
                const d = @abs(px - xs[i]) + @abs(py - ys[i]);
                total += d;
                if (d < best_d) {
                    best_d = d;
                    best_i = i;
                    tie = false;
                } else if (d == best_d) {
                    tie = true;
                }
            }
            if (total < 10000) region += 1;
            if (!tie) {
                areas[best_i] += 1;
                if (gx == 0 or gy == 0 or gx + 1 == w or gy + 1 == h) {
                    infinite[best_i] = true;
                }
            }
        }
    }

    var best_area: u64 = 0;
    for (0..n) |i| {
        if (!infinite[i]) best_area = @max(best_area, areas[i]);
    }
    print("part 1: {d}\n", .{best_area});
    print("part 2: {d}\n", .{region});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
