const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day07.txt");

pub fn main() !void {
    var crabs: List(i64) = .empty;
    defer crabs.deinit(gpa);
    var it = tokenizeSca(u8, trim(u8, data, " \n\r\t"), ',');
    while (it.next()) |tok| {
        try crabs.append(gpa, try parseInt(i64, tok, 10));
    }

    var min_p1: i64 = std.math.maxInt(i64);
    var min_p2: i64 = std.math.maxInt(i64);
    var lo: i64 = std.math.maxInt(i64);
    var hi: i64 = std.math.minInt(i64);
    for (crabs.items) |c| {
        lo = @min(lo, c);
        hi = @max(hi, c);
    }
    var pos = lo;
    while (pos <= hi) : (pos += 1) {
        var f1: i64 = 0;
        var f2: i64 = 0;
        for (crabs.items) |c| {
            const d: i64 = @intCast(@abs(pos - c));
            f1 += d;
            f2 += @divTrunc(d * (d + 1), 2);
        }
        min_p1 = @min(min_p1, f1);
        min_p2 = @min(min_p2, f2);
    }
    print("part 1: {d}\n", .{min_p1});
    print("part 2: {d}\n", .{min_p2});
}

// Useful stdlib functions
const tokenizeSca = std.mem.tokenizeScalar;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
