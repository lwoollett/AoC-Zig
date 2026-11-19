const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day10.txt");

pub fn main() !void {
    var x: i64 = 1;
    var cycle: u32 = 0;
    var total: i64 = 0;
    var crt: [6][40]u8 = @splat(@splat('.'));

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const ops: []const [2]struct { op: u8 } = &.{};
        _ = ops;
        var pending: ?i64 = null;
        if (std.mem.startsWith(u8, line, "addx")) {
            pending = try parseInt(i64, line[5..], 10);
        }
        for (0..if (pending != null) @as(u32, 2) else @as(u32, 1)) |_| {
            cycle += 1;
            // part 1: sample at 20, 60, ...
            if ((cycle + 20) % 40 == 0) {
                total += @as(i64, cycle) * x;
            }
            // part 2: draw
            const row = (cycle - 1) / 40;
            const col = (cycle - 1) % 40;
            const sprite: i64 = x;
            const ccol: i64 = @intCast(col);
            if (ccol >= sprite - 1 and ccol <= sprite + 1) {
                crt[row][col] = '#';
            }
        }
        if (pending) |v| x += v;
    }
    print("part 1: {d}\n", .{total});
    print("part 2:\n", .{});
    for (crt) |row| {
        for (row) |c| {
            print("{s}", .{if (c == '#') "#" else " "});
        }
        print("\n", .{});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
