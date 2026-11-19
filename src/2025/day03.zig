const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day03.txt");

/// maximum k-digit subsequence (keeps relative order) of a digit string,
/// interpreted as a big number (string compare: longer same-length lexicographic)
fn maxSubsequence(bank: []const u8, k: usize, out: *List(u8)) !void {
    out.clearRetainingCapacity();
    // greedy stack: keep the largest digits, drop when a bigger one arrives
    const drop = bank.len - k;
    var dropped: usize = 0;
    for (bank) |c| {
        while (out.items.len > 0 and dropped < drop and out.items[out.items.len - 1] < c) {
            _ = out.pop();
            dropped += 1;
        }
        if (out.items.len < k) {
            try out.append(gpa, c);
        } else {
            dropped += 1;
        }
    }
}

pub fn main() !void {
    var total1: u64 = 0;
    var total2: u64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        // part 1: max 2-digit value over ordered pairs
        var best: u64 = 0;
        for (line, 0..) |a, i| {
            for (line[i + 1 ..]) |b| {
                const v = @as(u64, a - '0') * 10 + (b - '0');
                best = @max(best, v);
            }
        }
        total1 += best;

        // part 2: max 12-digit subsequence as u128-summed
        var sub: List(u8) = .empty;
        defer sub.deinit(gpa);
        try maxSubsequence(line, 12, &sub);
        var v: u128 = 0;
        for (sub.items) |c| {
            v = v * 10 + (c - '0');
        }
        total2 += @intCast(v);
    }
    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{total2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
