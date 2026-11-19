const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day25.txt");

fn snafuToDec(s: []const u8) i64 {
    var v: i64 = 0;
    for (s) |c| {
        v *= 5;
        v += switch (c) {
            '2' => 2,
            '1' => 1,
            '0' => 0,
            '-' => -1,
            else => -2,
        };
    }
    return v;
}

fn decToSnafu(v_in: i64) ![]u8 {
    var buf: [64]u8 = undefined;
    var n: usize = 0;
    var v = v_in;
    while (v != 0) {
        var r = @mod(v, 5);
        v = @divFloor(v, 5);
        if (r > 2) {
            r -= 5;
            v += 1;
        }
        buf[n] = switch (r) {
            2 => '2',
            1 => '1',
            0 => '0',
            -1 => '-',
            else => '=',
        };
        n += 1;
    }
    // reverse
    var out = try gpa.alloc(u8, n);
    for (0..n) |i| {
        out[i] = buf[n - 1 - i];
    }
    return out;
}

pub fn main() !void {
    var total: i64 = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        total += snafuToDec(line);
    }
    const s = try decToSnafu(total);
    print("part 1: {s}\n", .{s});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
