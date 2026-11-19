const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day09.txt");

const P = [2]i32;

fn simulate(n_knots: usize) !u32 {
    var knots: [10]P = @splat(.{ 0, 0 });
    var visited = Map(P, void).init(gpa);
    defer visited.deinit();
    try visited.put(knots[n_knots - 1], {});

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const dir: P = switch (line[0]) {
            'U' => .{ 0, 1 },
            'D' => .{ 0, -1 },
            'L' => .{ -1, 0 },
            else => .{ 1, 0 },
        };
        const steps = try parseInt(u32, line[2..], 10);
        for (0..steps) |_| {
            knots[0][0] += dir[0];
            knots[0][1] += dir[1];
            for (1..n_knots) |i| {
                const dx = knots[i - 1][0] - knots[i][0];
                const dy = knots[i - 1][1] - knots[i][1];
                if (@abs(dx) <= 1 and @abs(dy) <= 1) break;
                knots[i][0] += sign(dx);
                knots[i][1] += sign(dy);
            }
            try visited.put(knots[n_knots - 1], {});
        }
    }
    return visited.count();
}

fn sign(v: i32) i32 {
    if (v > 0) return 1;
    if (v < 0) return -1;
    return 0;
}

pub fn main() !void {
    print("part 1: {d}\n", .{try simulate(2)});
    print("part 2: {d}\n", .{try simulate(10)});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
