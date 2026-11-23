const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day10.txt");

fn lookAndSay(input: []const u8, out: *List(u8)) !void {
    out.clearRetainingCapacity();
    try out.ensureTotalCapacity(gpa, input.len * 2 + 16);
    var i: usize = 0;
    while (i < input.len) {
        const c = input[i];
        var j = i + 1;
        while (j < input.len and input[j] == c) j += 1;
        const run_len = j - i;
        // runs of 1..3 dominate; emit their (count, digit) pairs directly
        switch (run_len) {
            1 => out.appendSliceAssumeCapacity(&[_]u8{ '1', c }),
            2 => out.appendSliceAssumeCapacity(&[_]u8{ '2', c }),
            3 => out.appendSliceAssumeCapacity(&[_]u8{ '3', c }),
            else => {
                var digits: [20]u8 = undefined;
                const n_str = std.fmt.bufPrint(&digits, "{d}{c}", .{ run_len, c }) catch unreachable;
                out.appendSliceAssumeCapacity(n_str);
            },
        }
        i = j;
    }
}

pub fn main() !void {
    const start = trim(u8, data, " \n\r\t");

    var cur: List(u8) = .empty;
    defer cur.deinit(gpa);
    var next: List(u8) = .empty;
    defer next.deinit(gpa);

    try cur.appendSlice(gpa, start);

    var i: usize = 0;
    while (i < 50) : (i += 1) {
        try lookAndSay(cur.items, &next);
        std.mem.swap(List(u8), &cur, &next);
        if (i == 39) {
            print("part 1: {d}\n", .{cur.items.len});
        }
    }
    print("part 2: {d}\n", .{cur.items.len});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
