const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day20.txt");

const max_ip: u64 = 4294967295;

pub fn main() !void {
    var ranges: List([2]u64) = .empty;
    defer ranges.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const dash = std.mem.findScalar(u8, line, '-').?;
        const lo = try parseInt(u64, line[0..dash], 10);
        const hi = try parseInt(u64, line[dash + 1 ..], 10);
        try ranges.append(gpa, .{ lo, hi });
    }

    std.mem.sort([2]u64, ranges.items, {}, struct {
        fn lessThan(_: void, a: [2]u64, b: [2]u64) bool {
            return a[0] < b[0];
        }
    }.lessThan);

    // merge walk: first gap = part 1; total gap count = part 2
    var first_free: ?u64 = null;
    var allowed: u64 = 0;
    var covered: u64 = 0; // current merge top
    var started = false;

    for (ranges.items) |r| {
        if (!started) {
            covered = r[1];
            started = true;
            continue;
        }
        if (r[0] > covered + 1) {
            if (first_free == null) first_free = covered + 1;
            allowed += r[0] - covered - 1;
        }
        covered = @max(covered, r[1]);
    }
    if (max_ip > covered) {
        if (first_free == null) first_free = covered + 1;
        allowed += max_ip - covered;
    }

    print("part 1: {d}\n", .{first_free.?});
    print("part 2: {d}\n", .{allowed});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
