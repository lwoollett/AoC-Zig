const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day04.txt");

fn nonDecreasing(n: i32) bool {
    var digits: [6]u8 = undefined;
    var v = n;
    var i: usize = 6;
    while (i > 0) {
        i -= 1;
        digits[i] = @intCast(@mod(v, 10));
        v = @divTrunc(v, 10);
    }
    for (0..5) |k| {
        if (digits[k] > digits[k + 1]) return false;
    }
    return true;
}

fn digitsOf(n: i32) [6]u8 {
    var digits: [6]u8 = undefined;
    var v = n;
    var i: usize = 6;
    while (i > 0) {
        i -= 1;
        digits[i] = @intCast(@mod(v, 10));
        v = @divTrunc(v, 10);
    }
    return digits;
}

fn hasAdjacentPair(digits: [6]u8) bool {
    for (0..5) |k| {
        if (digits[k] == digits[k + 1]) return true;
    }
    return false;
}

/// A pair that is exactly two (not part of a longer run).
fn hasIsolatedPair(digits: [6]u8) bool {
    var i: usize = 0;
    while (i < 6) {
        var run: usize = 1;
        while (i + run < 6 and digits[i + run] == digits[i]) run += 1;
        if (run == 2) return true;
        i += run;
    }
    return false;
}

pub fn main() !void {
    const dash = std.mem.findScalar(u8, data, '-').?;
    const lo = try parseInt(i32, data[0..dash], 10);
    const hi = try parseInt(i32, trim(u8, data[dash + 1 ..], " \n\r"), 10);

    var count1: u32 = 0;
    var count2: u32 = 0;
    var n = lo;
    while (n <= hi) : (n += 1) {
        if (!nonDecreasing(n)) continue;
        const d = digitsOf(n);
        if (hasAdjacentPair(d)) count1 += 1;
        if (hasIsolatedPair(d)) count2 += 1;
    }

    print("part 1: {d}\n", .{count1});
    print("part 2: {d}\n", .{count2});
}

// Useful stdlib functions
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
