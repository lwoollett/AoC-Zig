const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day20.txt");

/// Mix `rounds` times; return the groove-coordinate sum. Moving an element
/// is remove + insert at (at + shift) mod (n-1) — a couple of memmoves
/// instead of walking one adjacent swap at a time.
fn solve(rounds: usize, key: i64) !i64 {
    var nums: List(i64) = .empty;
    defer nums.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        try nums.append(gpa, (try parseInt(i64, line, 10)) * key);
    }
    const n = nums.items.len;

    // order[i] = which original index is at position i
    var order: List(usize) = .empty;
    defer order.deinit(gpa);
    try order.ensureTotalCapacity(gpa, n);
    for (0..n) |i| {
        try order.append(gpa, i);
    }

    for (0..rounds) |_| {
        for (0..n) |mix_i| {
            var at: usize = 0;
            for (order.items, 0..) |v, p| {
                if (v == mix_i) {
                    at = p;
                    break;
                }
            }
            const shift: usize = @intCast(@mod(nums.items[mix_i], @as(i64, @intCast(n - 1))));
            if (shift == 0) continue;
            const item = order.orderedRemove(at);
            const to = (at + shift) % (n - 1);
            try order.insert(gpa, to, item);
        }
    }

    var zero_pos: usize = 0;
    for (order.items, 0..) |v, p| {
        if (nums.items[v] == 0) {
            zero_pos = p;
            break;
        }
    }
    var total: i64 = 0;
    for ([3]usize{ 1000, 2000, 3000 }) |off| {
        const p = (zero_pos + off) % n;
        total += nums.items[order.items[p]];
    }
    return total;
}

pub fn main() !void {
    print("part 1: {d}\n", .{try solve(1, 1)});
    print("part 2: {d}\n", .{try solve(10, 811589153)});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
