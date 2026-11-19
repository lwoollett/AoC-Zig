const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
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
const splitAny = std.mem.splitAny;
const indexOf = std.mem.findScalar;
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
