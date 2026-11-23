const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

const data = @embedFile("data/day06.txt");

pub fn main() !void {
    // rows: last is operators, others are digits
    var rows: List([]const u8) = .empty;
    defer rows.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line_raw| {
        const line = trimEnd(u8, line_raw, " \r");
        if (line.len > 0) {
            try rows.append(gpa, line);
        }
    }
    const ops_row = rows.items[rows.items.len - 1];
    const data_rows = rows.items[0 .. rows.items.len - 1];
    const width = ops_row.len;
    var max_w = width;
    for (data_rows) |r| {
        max_w = @max(max_w, r.len);
    }

    // column groups: maximal runs of columns containing a digit or operator
    const occupied = try gpa.alloc(bool, max_w);
    defer gpa.free(occupied);
    @memset(occupied, false);
    for (data_rows) |r| {
        for (r, 0..) |c, x| {
            if (c != ' ') occupied[x] = true;
        }
    }
    for (ops_row, 0..) |c, x| {
        if (c != ' ') occupied[x] = true;
    }

    var total1: u128 = 0;
    var total2: u128 = 0;

    var x: usize = 0;
    while (x < max_w) {
        if (!occupied[x]) {
            x += 1;
            continue;
        }
        const g0 = x;
        while (x < max_w and occupied[x]) x += 1;
        const g1 = x; // group = columns [g0, g1)

        // operator in the group
        var op: u8 = '+';
        for (ops_row[g0..@min(g1, ops_row.len)]) |c| {
            if (c == '*' or c == '+') op = c;
        }

        // part 1: per data row, concatenate digits in [g0, g1) left-to-right
        {
            var acc: u128 = 0;
            var first = true;
            for (data_rows) |r| {
                var digits: List(u8) = .empty;
                defer digits.deinit(gpa);
                for (r[g0..@min(g1, r.len)]) |c| {
                    if (c != ' ') {
                        try digits.append(gpa, c);
                    }
                }
                if (digits.items.len == 0) continue;
                var v: u128 = 0;
                for (digits.items) |c| {
                    v = v * 10 + (c - '0');
                }
                if (first) {
                    acc = v;
                    first = false;
                } else {
                    acc = if (op == '*') acc * v else acc + v;
                }
            }
            total1 += acc;
        }

        // part 2: per column in [g0, g1), read top-to-bottom (skip spaces);
        // numbers are the columns read RIGHT-TO-LEFT
        {
            var acc: u128 = 0;
            var first = true;
            var cx = g1;
            while (cx > g0) {
                cx -= 1;
                var v: u128 = 0;
                var any = false;
                for (data_rows) |r| {
                    if (cx < r.len and r[cx] != ' ') {
                        v = v * 10 + (r[cx] - '0');
                        any = true;
                    }
                }
                if (!any) continue;
                if (first) {
                    acc = v;
                    first = false;
                } else {
                    acc = if (op == '*') acc * v else acc + v;
                }
            }
            total2 += acc;
        }
    }

    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{total2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const trimEnd = std.mem.trimEnd;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
