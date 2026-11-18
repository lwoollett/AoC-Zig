const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day06.txt");

pub fn main() !void {
    var total1: u32 = 0;
    var total2: u32 = 0;

    var group: List([]const u8) = .empty;
    defer group.deinit(gpa);

    var lines = splitAny(u8, data, "\n");
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) {
            if (group.items.len > 0) {
                // union
                var seen = Map(u8, void).init(gpa);
                defer seen.deinit();
                for (group.items) |person| {
                    for (person) |c| {
                        try seen.put(c, {});
                    }
                }
                total1 += seen.count();
                // intersection
                var c: u8 = 'a';
                while (c <= 'z') : (c += 1) {
                    var all = true;
                    for (group.items) |person| {
                        if (indexOf(u8, person, c) == null) {
                            all = false;
                            break;
                        }
                    }
                    if (all) total2 += 1;
                }
                group.clearRetainingCapacity();
            }
            continue;
        }
        try group.append(gpa, line);
    }

    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{total2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.findScalar;
const indexOfAny = std.mem.findAny;
const indexOfStr = std.mem.findPos;
const lastIndexOf = std.mem.findScalarLast;
const lastIndexOfAny = std.mem.findLastAny;
const lastIndexOfStr = std.mem.findLastLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
