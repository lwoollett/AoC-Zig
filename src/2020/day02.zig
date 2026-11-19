const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day02.txt");

pub fn main() !void {
    var valid1: u32 = 0;
    var valid2: u32 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "min-max c: password"
        const dash = indexOf(u8, line, '-').?;
        const colon = indexOf(u8, line, ':').?;
        const lo = try parseInt(u32, line[0..dash], 10);
        const hi = try parseInt(u32, line[dash + 1 .. colon - 2], 10);
        const c = line[colon - 1];
        const pass = line[colon + 2 ..];

        var count: u32 = 0;
        for (pass) |ch| {
            if (ch == c) count += 1;
        }
        if (count >= lo and count <= hi) valid1 += 1;

        const p1 = pass[lo - 1] == c;
        const p2 = pass[hi - 1] == c;
        if (p1 != p2) valid2 += 1;
    }
    print("part 1: {d}\n", .{valid1});
    print("part 2: {d}\n", .{valid2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
