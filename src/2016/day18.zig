const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day18.txt");

fn countSafe(first: []const u8, rows: usize) !u64 {
    const width = first.len;
    if (width > 127) return error.TooWide;
    // rows as bitmasks: trap[i] = 1. next row's traps are exactly where the
    // left and right neighbours differ: (cur<<1) ^ (cur>>1), with virtual
    // safe ('.') cells beyond both edges — the mask keeps the width honest.
    var cur: u128 = 0;
    for (first, 0..) |c, i| {
        if (c == '^') cur |= @as(u128, 1) << @intCast(i);
    }
    const mask: u128 = if (width == 127) std.math.maxInt(u128) else (@as(u128, 1) << @intCast(width)) - 1;
    var safe: u64 = width - @popCount(cur);
    var row: usize = 1;
    while (row < rows) : (row += 1) {
        cur = ((cur << 1) ^ (cur >> 1)) & mask;
        safe += width - @popCount(cur);
    }
    return safe;
}

pub fn main() !void {
    const first = trim(u8, data, " \n\r\t");
    print("part 1: {d}\n", .{try countSafe(first, 40)});
    print("part 2: {d}\n", .{try countSafe(first, 400_000)});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
