const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

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

    // for each pair of tiles as opposite corners, count other tiles inside
    // the closed rectangle; valid if exactly the 2 corners
    var best: i64 = 0;
    for (tiles.items, 0..) |a, i| {
        for (tiles.items[i + 1 ..]) |b| {
            const x0 = @min(a[0], b[0]);
            const x1 = @max(a[0], b[0]);
            const y0 = @min(a[1], b[1]);
            const y1 = @max(a[1], b[1]);
            var inside: usize = 0;
            for (tiles.items) |t| {
                if (t[0] >= x0 and t[0] <= x1 and t[1] >= y0 and t[1] <= y1) {
                    inside += 1;
                }
            }
            if (inside == 2) {
                const area = (x1 - x0 + 1) * (y1 - y0 + 1);
                best = @max(best, area);
            }
        }
    }
    print("part 1: {d}\n", .{best});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
