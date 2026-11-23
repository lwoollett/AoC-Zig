const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day03.txt");

fn prio(c: u8) u64 {
    if (c >= 'a' and c <= 'z') return c - 'a' + 1;
    return c - 'A' + 27;
}

fn common2(a: []const u8, b: []const u8) ?u8 {
    for (a) |ca| {
        if (indexOf(u8, b, ca) != null) return ca;
    }
    return null;
}

fn common3(a: []const u8, b: []const u8, c: []const u8) ?u8 {
    for (a) |ca| {
        if (indexOf(u8, b, ca) != null and indexOf(u8, c, ca) != null) return ca;
    }
    return null;
}

pub fn main() !void {
    var total1: u64 = 0;
    var total2: u64 = 0;

    var lines: List([]const u8) = .empty;
    defer lines.deinit(gpa);
    var it = tokenizeAny(u8, data, "\n");
    while (it.next()) |line| {
        try lines.append(gpa, line);
        const half = line.len / 2;
        total1 += prio(common2(line[0..half], line[half..]) orelse 0);
    }

    var i: usize = 0;
    while (i + 2 < lines.items.len) : (i += 3) {
        total2 += prio(common3(lines.items[i], lines.items[i + 1], lines.items[i + 2]) orelse 0);
    }
    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{total2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
