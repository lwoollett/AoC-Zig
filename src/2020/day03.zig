const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day03.txt");

fn countTrees(lines: []const []const u8, dx: usize, dy: usize) u64 {
    var trees: u64 = 0;
    var x: usize = 0;
    var y: usize = 0;
    while (y < lines.len) : (y += dy) {
        const line = lines[y];
        if (line[x % line.len] == '#') trees += 1;
        x += dx;
    }
    return trees;
}

pub fn main() !void {
    var lines: List([]const u8) = .empty;
    defer lines.deinit(gpa);
    var it = tokenizeAny(u8, data, "\n");
    while (it.next()) |line| {
        try lines.append(gpa, line);
    }

    print("part 1: {d}\n", .{countTrees(lines.items, 3, 1)});

    const slopes = [_][2]usize{
        .{ 1, 1 }, .{ 3, 1 }, .{ 5, 1 }, .{ 7, 1 }, .{ 1, 2 },
    };
    var product: u64 = 1;
    for (slopes) |s| {
        product *= countTrees(lines.items, s[0], s[1]);
    }
    print("part 2: {d}\n", .{product});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
