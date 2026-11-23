const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day06.txt");

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");

    const first = lines.next().?;
    const width = first.len;
    var counts = try gpa.alloc([26]u32, width);
    defer gpa.free(counts);
    @memset(counts, @splat(0));

    for (first, 0..) |c, i| counts[i][c - 'a'] += 1;
    while (lines.next()) |line| {
        for (line, 0..) |c, i| {
            counts[i][c - 'a'] += 1;
        }
    }

    var most: [64]u8 = undefined;
    var least: [64]u8 = undefined;
    for (counts, 0..) |col, i| {
        var mi: usize = 0;
        for (col, 0..) |n, j| {
            if (n > col[mi]) mi = j;
        }
        var li: usize = 0;
        var seen_nonzero = false;
        for (col, 0..) |n, j| {
            if (n == 0) continue;
            if (!seen_nonzero or n < col[li]) {
                li = j;
                seen_nonzero = true;
            }
        }
        most[i] = @intCast('a' + mi);
        least[i] = @intCast('a' + li);
    }

    print("part 1: {s}\n", .{most[0..counts.len]});
    print("part 2: {s}\n", .{least[0..counts.len]});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
