const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day08.txt");

fn segsOf(s: []const u8) u8 {
    var m: u8 = 0;
    for (s) |c| {
        m |= @as(u8, 1) << @intCast(c - 'a');
    }
    return m;
}

fn popcount7(v: u8) u32 {
    return @popCount(v);
}

pub fn main() !void {
    var total1: u64 = 0;
    var total2: u64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const bar = indexOf(u8, line, '|').?;
        const sig_part = line[0..bar];
        const out_part = line[bar + 2 ..];

        var sigs: List(u8) = .empty;
        defer sigs.deinit(gpa);
        var it = tokenizeSca(u8, sig_part, ' ');
        while (it.next()) |tok| {
            try sigs.append(gpa, segsOf(tok));
        }

        var outputs: List(u8) = .empty;
        defer outputs.deinit(gpa);
        var oit = tokenizeSca(u8, out_part, ' ');
        while (oit.next()) |tok| {
            const v = segsOf(tok);
            try outputs.append(gpa, v);
            const n = popcount7(v);
            if (n == 2 or n == 3 or n == 4 or n == 7) total1 += 1;
        }

        // decode mapping
        var one: u8 = 0;
        var four: u8 = 0;
        for (sigs.items) |s| {
            switch (popcount7(s)) {
                2 => one = s,
                4 => four = s,
                else => {},
            }
        }
        var num: u64 = 0;
        for (outputs.items) |o| {
            var d: u8 = 0;
            switch (popcount7(o)) {
                2 => d = 1,
                3 => d = 7,
                4 => d = 4,
                7 => d = 8,
                5 => {
                    // 2, 3, 5
                    if (o & one == one) {
                        d = 3; // superset of 1
                    } else if (popcount7(o & four) == 3) {
                        d = 5;
                    } else {
                        d = 2;
                    }
                },
                6 => {
                    // 0, 6, 9
                    if (o & four == four) {
                        d = 9;
                    } else if (o & one == one) {
                        d = 0;
                    } else {
                        d = 6;
                    }
                },
                else => {},
            }
            num = num * 10 + d;
        }
        total2 += num;
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
// Only unmodified days will be modified.
