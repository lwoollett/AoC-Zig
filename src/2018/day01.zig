const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day01.txt");

pub fn main() !void {
    var total: i64 = 0;
    var lines0 = tokenizeAny(u8, data, "\n");
    while (lines0.next()) |line| {
        total += try parseInt(i64, line, 10);
    }

    var sum: i64 = 0;
    var seen = Map(i64, void).init(gpa);
    defer seen.deinit();
    var repeat: ?i64 = null;

    outer: while (repeat == null) {
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            const v = try parseInt(i64, line, 10);
            sum += v;
            if (repeat == null and seen.contains(sum)) {
                repeat = sum;
                break :outer;
            }
            try seen.put(sum, {});
        }
    }

    print("part 1: {d}\n", .{total});
    print("part 2: {d}\n", .{repeat.?});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
