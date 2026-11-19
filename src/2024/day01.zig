const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day01.txt");

pub fn main() !void {
    var left: List(u64) = .empty;
    var right: List(u64) = .empty;
    defer left.deinit(gpa);
    defer right.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const sp = indexOfAny(u8, line, " \t").?;
        try left.append(gpa, try parseInt(u64, line[0..sp], 10));
        var it = tokenizeAny(u8, line[sp..], " \t");
        try right.append(gpa, try parseInt(u64, it.next().?, 10));
    }

    std.mem.sort(u64, left.items, {}, comptime std.sort.asc(u64));
    std.mem.sort(u64, right.items, {}, comptime std.sort.asc(u64));

    var total1: u64 = 0;
    for (left.items, right.items) |a, b| {
        total1 += if (a > b) a - b else b - a;
    }
    print("part 1: {d}\n", .{total1});

    var counts = Map(u64, u64).init(gpa);
    defer counts.deinit();
    for (right.items) |b| {
        const gop = try counts.getOrPut(b);
        if (!gop.found_existing) gop.value_ptr.* = 0;
        gop.value_ptr.* += 1;
    }
    var total2: u64 = 0;
    for (left.items) |a| {
        total2 += a * (counts.get(a) orelse 0);
    }
    print("part 2: {d}\n", .{total2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOfAny = std.mem.findAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;
const asc = std.sort.asc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
