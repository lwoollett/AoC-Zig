const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day02.txt");

pub fn main() !void {
    var ids: List([]const u8) = .empty;
    defer ids.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        try ids.append(gpa, line);
    }

    var twos: u32 = 0;
    var threes: u32 = 0;
    for (ids.items) |id| {
        var counts: [26]u32 = @splat(0);
        for (id) |c| counts[c - 'a'] += 1;
        var has2 = false;
        var has3 = false;
        for (counts) |n| {
            if (n == 2) has2 = true;
            if (n == 3) has3 = true;
        }
        if (has2) twos += 1;
        if (has3) threes += 1;
    }
    print("part 1: {d}\n", .{twos * threes});

    // part 2: pair differing in exactly one position
    outer: for (ids.items, 0..) |a, i| {
        for (ids.items[i + 1 ..]) |b| {
            if (a.len != b.len) continue;
            var diff: usize = 0;
            var diff_at: usize = 0;
            for (a, 0..) |ca, k| {
                if (ca != b[k]) {
                    diff += 1;
                    diff_at = k;
                    if (diff > 1) break;
                }
            }
            if (diff == 1) {
                print("part 2: {s}{s}\n", .{ a[0..diff_at], a[diff_at + 1 ..] });
                break :outer;
            }
        }
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
