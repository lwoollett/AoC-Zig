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

const size = 1000;
var grid1: [size][size]bool = @splat(@splat(false));
var grid2: [size][size]u16 = @splat(@splat(0));

fn parseIntAt(comptime T: type, s: []const u8, i: *usize) T {
    const start = i.*;
    while (i.* < s.len and s[i.*] >= '0' and s[i.*] <= '9') i.* += 1;
    return parseInt(T, s[start..i.*], 10) catch unreachable;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "turn on 0,0 through 999,999" | "toggle ..." | "turn off ..."
        var mode: u8 = 0; // 0=on 1=off 2=toggle
        var rest = line;
        if (startsWith(rest, "turn on")) {
            mode = 0;
            rest = rest["turn on ".len..];
        } else if (startsWith(rest, "turn off")) {
            mode = 1;
            rest = rest["turn off ".len..];
        } else {
            mode = 2;
            rest = rest["toggle ".len..];
        }

        var i: usize = 0;
        const x1 = parseIntAt(u16, rest, &i);
        i += 1; // ,
        const y1 = parseIntAt(u16, rest, &i);
        i += " through ".len;
        const x2 = parseIntAt(u16, rest, &i);
        i += 1;
        const y2 = parseIntAt(u16, rest, &i);

        var y = y1;
        while (y <= y2) : (y += 1) {
            var x = x1;
            while (x <= x2) : (x += 1) {
                switch (mode) {
                    0 => {
                        grid1[y][x] = true;
                        grid2[y][x] += 1;
                    },
                    1 => {
                        grid1[y][x] = false;
                        if (grid2[y][x] > 0) grid2[y][x] -= 1;
                    },
                    else => {
                        grid1[y][x] = !grid1[y][x];
                        grid2[y][x] += 2;
                    },
                }
            }
        }
    }

    var lit: usize = 0;
    var bright: u64 = 0;
    for (grid1) |row| {
        for (row) |on| {
            if (on) lit += 1;
        }
    }
    for (grid2) |row| {
        for (row) |b| bright += b;
    }

    print("part 1: {d}\n", .{lit});
    print("part 2: {d}\n", .{bright});
}

fn startsWith(s: []const u8, prefix: []const u8) bool {
    return std.mem.startsWith(u8, s, prefix);
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
