const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day10.txt");

pub fn main() !void {
    var nums: List(u64) = .empty;
    defer nums.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        try nums.append(gpa, try parseInt(u64, line, 10));
    }
    std.mem.sort(u64, nums.items, {}, comptime std.sort.asc(u64));

    var diff1: u32 = 0;
    var diff3: u32 = 1; // final adapter
    var prev: u64 = 0;
    for (nums.items) |n| {
        switch (n - prev) {
            1 => diff1 += 1,
            3 => diff3 += 1,
            else => {},
        }
        prev = n;
    }
    print("part 1: {d}\n", .{diff1 * diff3});

    // part 2: count arrangements (DP; prepend the 0-jolt outlet)
    try nums.insert(gpa, 0, 0);
    var dp = try gpa.alloc(u64, nums.items.len);
    defer gpa.free(dp);
    @memset(dp, 0);
    dp[0] = 1;
    for (nums.items, 0..) |n, i| {
        if (dp[i] == 0) continue;
        var j = i + 1;
        while (j < nums.items.len and nums.items[j] - n <= 3) : (j += 1) {
            dp[j] += dp[i];
        }
    }
    print("part 2: {d}\n", .{dp[nums.items.len - 1]});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;
const asc = std.sort.asc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
