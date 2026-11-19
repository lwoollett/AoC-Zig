const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day15.txt");

const fa: u64 = 16807;
const fb: u64 = 48271;
const mask: u64 = 2147483647;
const low16: u64 = 0xffff;

fn lastInt(line: []const u8) []const u8 {
    var last: []const u8 = "";
    var it = tokenizeAny(u8, line, " ");
    while (it.next()) |t| last = t;
    return last;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    const line_a = lines.next().?;
    const line_b = lines.next().?;
    const seed_a = try parseInt(u64, lastInt(line_a), 10);
    const seed_b = try parseInt(u64, lastInt(line_b), 10);

    // both parts are independent lcg loops — run them concurrently
    var count: u32 = 0;
    const t = try std.Thread.spawn(.{}, part1, .{ seed_a, seed_b, &count });
    const count2 = part2(seed_a, seed_b);
    t.join();
    print("part 1: {d}\n", .{count});
    print("part 2: {d}\n", .{count2});
}

/// Part 1: 40M plain pairs.
fn part1(seed_a: u64, seed_b: u64, count: *u32) void {
    var a = seed_a;
    var b = seed_b;
    var c: u32 = 0;
    var i: u64 = 0;
    while (i < 40_000_000) : (i += 1) {
        a = a * fa % mask;
        b = b * fb % mask;
        if (a & low16 == b & low16) c += 1;
    }
    count.* = c;
}

/// Part 2: 5M picky pairs.
fn part2(seed_a: u64, seed_b: u64) u32 {
    var a = seed_a;
    var b = seed_b;
    var count: u32 = 0;
    var i: u64 = 0;
    while (i < 5_000_000) : (i += 1) {
        while (true) {
            a = a * fa % mask;
            if (a % 4 == 0) break;
        }
        while (true) {
            b = b * fb % mask;
            if (b % 8 == 0) break;
        }
        if (a & low16 == b & low16) count += 1;
    }
    return count;
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
