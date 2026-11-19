const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day05.txt");

const P = [2]i32;

var counts = Map(P, u32).init(std.heap.page_allocator);

fn markLine(x1: i32, y1: i32, x2: i32, y2: i32, diagonals: bool) !void {
    const dx: i32 = if (x2 > x1) 1 else if (x2 < x1) -1 else 0;
    const dy: i32 = if (y2 > y1) 1 else if (y2 < y1) -1 else 0;
    if (dx != 0 and dy != 0 and !diagonals) return;
    var x = x1;
    var y = y1;
    while (true) {
        const gop = try counts.getOrPut(.{ x, y });
        if (!gop.found_existing) gop.value_ptr.* = 0;
        gop.value_ptr.* += 1;
        if (x == x2 and y == y2) break;
        x += dx;
        y += dy;
    }
}

fn danger(comptime include_diag: bool) !u32 {
    counts.clearRetainingCapacity();
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const comma1 = indexOf(u8, line, ',').?;
        const arrow = std.mem.indexOf(u8, line, " -> ").?;
        const comma2 = lastIndexOf(u8, line, ',').?;
        const x1 = try parseInt(i32, line[0..comma1], 10);
        const y1 = try parseInt(i32, line[comma1 + 1 .. arrow], 10);
        const x2 = try parseInt(i32, line[arrow + 4 .. comma2], 10);
        const y2 = try parseInt(i32, line[comma2 + 1 ..], 10);
        try markLine(x1, y1, x2, y2, include_diag);
    }
    var overlap: u32 = 0;
    var it = counts.valueIterator();
    while (it.next()) |v| {
        if (v.* >= 2) overlap += 1;
    }
    return overlap;
}

pub fn main() !void {
    print("part 1: {d}\n", .{try danger(false)});
    print("part 2: {d}\n", .{try danger(true)});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const lastIndexOf = std.mem.findScalarLast;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
