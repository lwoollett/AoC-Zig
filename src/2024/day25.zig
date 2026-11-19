const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day25.txt");

pub fn main() !void {
    var locks: List([5]u32) = .empty;
    var keys: List([5]u32) = .empty;
    defer locks.deinit(gpa);
    defer keys.deinit(gpa);

    var lines = splitSca(u8, data, '\n');
    var rows: List([]const u8) = .empty;
    defer rows.deinit(gpa);
    while (true) {
        const line_raw = lines.next() orelse break;
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) {
            if (rows.items.len > 0) {
                try classify(rows.items, &locks, &keys);
                rows.clearRetainingCapacity();
            }
            continue;
        }
        try rows.append(gpa, line);
    }
    if (rows.items.len > 0) {
        try classify(rows.items, &locks, &keys);
    }

    var count: u64 = 0;
    for (locks.items) |l| {
        for (keys.items) |k| {
            var ok = true;
            for (0..5) |c| {
                if (l[c] + k[c] > 5) ok = false;
            }
            if (ok) count += 1;
        }
    }
    print("part 1: {d}\n", .{count});
}

fn classify(rows: []const []const u8, locks: *List([5]u32), keys: *List([5]u32)) !void {
    // lock: first row all '#'; key: last row all '#'
    var first_full = true;
    var last_full = true;
    for (rows[0]) |c| {
        if (c != '#') first_full = false;
    }
    for (rows[rows.len - 1]) |c| {
        if (c != '#') last_full = false;
    }
    var heights: [5]u32 = @splat(0);
    for (rows) |row| {
        for (row, 0..) |c, x| {
            if (c == '#') heights[x] += 1;
        }
    }
    // heights include the solid row: subtract 1 per column
    var h2: [5]u32 = undefined;
    for (0..5) |x| {
        h2[x] = heights[x] - 1;
    }
    if (first_full) {
        try locks.append(gpa, h2);
    } else if (last_full) {
        try keys.append(gpa, h2);
    }
}

// Useful stdlib functions
const splitSca = std.mem.splitScalar;
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
