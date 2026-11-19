const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day09.txt");

pub fn main() !void {
    var total1: i64 = 0;
    var total2: i64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var hist: List(i64) = .empty;
        defer hist.deinit(gpa);
        var it = tokenizeSca(u8, line, ' ');
        while (it.next()) |tok| {
            try hist.append(gpa, try parseInt(i64, tok, 10));
        }
        var firsts: List(i64) = .empty;
        defer firsts.deinit(gpa);
        var cur = try hist.clone(gpa);
        defer cur.deinit(gpa);
        while (true) {
            try firsts.append(gpa, cur.items[0]);
            var all_zero = true;
            var next: List(i64) = .empty;
            for (cur.items[1..], 0..) |v, i| {
                const d = v - cur.items[i];
                if (d != 0) all_zero = false;
                try next.append(gpa, d);
            }
            cur.deinit(gpa);
            cur = next;
            if (all_zero) break;
        }
        // extrapolate forward: sum of last elements of each difference level
        {
            var last: i64 = 0;
            var lvl = try hist.clone(gpa);
            while (true) {
                last += lvl.items[lvl.items.len - 1];
                var all_zero = true;
                var nxt: List(i64) = .empty;
                for (lvl.items[1..], 0..) |v, i| {
                    const d = v - lvl.items[i];
                    if (d != 0) all_zero = false;
                    try nxt.append(gpa, d);
                }
                lvl.deinit(gpa);
                lvl = nxt;
                if (all_zero) break;
            }
            total1 += last;
        }
        // extrapolate backward
        {
            var prev: i64 = 0;
            var i: usize = firsts.items.len;
            while (i > 0) {
                i -= 1;
                prev = firsts.items[i] - prev;
            }
            total2 += prev;
        }
    }
    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{total2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSca = std.mem.tokenizeScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
