const std = @import("std");
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day06.txt");

pub fn main() !void {
    var orbits = StrMap([]const u8).init(gpa); // object -> what it orbits
    defer orbits.deinit();

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const paren = std.mem.findScalar(u8, line, ')').?;
        try orbits.put(line[paren + 1 ..], line[0..paren]);
    }

    // part 1: total direct+indirect orbits
    var total: u64 = 0;
    var it = orbits.keyIterator();
    while (it.next()) |obj| {
        var cur = obj.*;
        while (orbits.get(cur)) |parent| {
            total += 1;
            cur = parent;
        }
    }
    print("part 1: {d}\n", .{total});

    // part 2: transfers between YOU and SAN (exclude the -1 shared COM)
    var you_chain = StrMap(u32).init(gpa);
    defer you_chain.deinit();
    {
        var steps: u32 = 0;
        var cur: []const u8 = orbits.get("YOU").?;
        while (orbits.get(cur)) |parent| {
            steps += 1;
            try you_chain.put(parent, steps);
            cur = parent;
        }
    }
    {
        var steps: u32 = 0;
        var cur: []const u8 = orbits.get("SAN").?;
        while (orbits.get(cur)) |parent| {
            steps += 1;
            if (you_chain.get(parent)) |up| {
                print("part 2: {d}\n", .{steps + up});
                return;
            }
            cur = parent;
        }
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
