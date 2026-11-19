const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day11.txt");

// cube coordinates; distance = (|x|+|y|+|z|)/2
fn delta(dir: []const u8) [3]i64 {
    if (std.mem.eql(u8, dir, "n")) return .{ 0, 1, -1 };
    if (std.mem.eql(u8, dir, "s")) return .{ 0, -1, 1 };
    if (std.mem.eql(u8, dir, "ne")) return .{ 1, 0, -1 };
    if (std.mem.eql(u8, dir, "sw")) return .{ -1, 0, 1 };
    if (std.mem.eql(u8, dir, "se")) return .{ 1, -1, 0 };
    return .{ -1, 1, 0 }; // nw
}

fn dist(x: i64, y: i64, z: i64) u64 {
    return (@abs(x) + @abs(y) + @abs(z)) / 2;
}

pub fn main() !void {
    var x: i64 = 0;
    var y: i64 = 0;
    var z: i64 = 0;
    var maxd: u64 = 0;

    var it = tokenizeAny(u8, data, ", \n");
    while (it.next()) |dir| {
        const d = delta(dir);
        x += d[0];
        y += d[1];
        z += d[2];
        maxd = @max(maxd, dist(x, y, z));
    }

    print("part 1: {d}\n", .{dist(x, y, z)});
    print("part 2: {d}\n", .{maxd});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
