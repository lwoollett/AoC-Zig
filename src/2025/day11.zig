const std = @import("std");
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day11.txt");

var adj = StrMap(*List([]const u8)).init(std.heap.page_allocator);
var memo = StrMap(u64).init(std.heap.page_allocator);

fn countPaths(name: []const u8) !u64 {
    if (memo.get(name)) |v| return v;
    if (std.mem.eql(u8, name, "out")) return 1;
    var total: u64 = 0;
    if (adj.get(name)) |neighbors| {
        for (neighbors.items) |nb| {
            total += try countPaths(nb);
        }
    }
    try memo.put(name, total);
    return total;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const colon = indexOf(u8, line, ':').?;
        const src = try std.heap.page_allocator.dupe(u8, line[0..colon]);
        const gop = try adj.getOrPut(src);
        if (!gop.found_existing) {
            const l = try std.heap.page_allocator.create(List([]const u8));
            l.* = .empty;
            gop.value_ptr.* = l;
        }
        var it = tokenizeSca(u8, line[colon + 1 ..], ' ');
        while (it.next()) |tok| {
            try gop.value_ptr.*.append(std.heap.page_allocator, try std.heap.page_allocator.dupe(u8, tok));
        }
    }

    print("part 1: {d}\n", .{try countPaths("you")});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSca = std.mem.tokenizeScalar;
const indexOf = std.mem.findScalar;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
