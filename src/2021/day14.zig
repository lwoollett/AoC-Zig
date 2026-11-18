const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day14.txt");

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    const template = lines.next().?;

    // pair counts: key = two chars packed
    var pairs = Map(u64, u64).init(gpa);
    defer pairs.deinit();
    var rules = Map(u64, u8).init(gpa); // AB -> C: key AB, value C
    defer rules.deinit();

    for (template[0 .. template.len - 1], 0..) |_, i| {
        const key = (@as(u64, template[i]) << 8) | template[i + 1];
        const gop = try pairs.getOrPut(key);
        if (!gop.found_existing) gop.value_ptr.* = 0;
        gop.value_ptr.* += 1;
    }

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const arrow = std.mem.indexOf(u8, line, " -> ").?;
        const key = (@as(u64, line[0]) << 8) | line[1];
        try rules.put(key, line[arrow + 4]);
    }

    var counts: [256]u64 = @splat(0);
    for (template) |c| counts[c] += 1;

    var step: u32 = 0;
    while (step < 40) : (step += 1) {
        var next = Map(u64, u64).init(gpa);
        var it = pairs.iterator();
        while (it.next()) |e| {
            const key = e.key_ptr.*;
            const a: u8 = @intCast(key >> 8);
            const b: u8 = @intCast(key & 0xff);
            if (rules.get(key)) |c| {
                const k1 = (@as(u64, a) << 8) | c;
                const k2 = (@as(u64, c) << 8) | b;
                const g1 = try next.getOrPut(k1);
                if (!g1.found_existing) g1.value_ptr.* = 0;
                g1.value_ptr.* += e.value_ptr.*;
                const g2 = try next.getOrPut(k2);
                if (!g2.found_existing) g2.value_ptr.* = 0;
                g2.value_ptr.* += e.value_ptr.*;
                if (step >= 10) {} // counts updated below instead
                counts[c] += e.value_ptr.*;
            } else {
                const g = try next.getOrPut(key);
                if (!g.found_existing) g.value_ptr.* = 0;
                g.value_ptr.* += e.value_ptr.*;
            }
        }
        pairs.deinit();
        pairs = next;
        if (step == 9) {
            var most: u64 = 0;
            var least: u64 = std.math.maxInt(u64);
            for (counts) |c| {
                if (c == 0) continue;
                most = @max(most, c);
                least = @min(least, c);
            }
            print("part 1: {d}\n", .{most - least});
        }
    }

    var most: u64 = 0;
    var least: u64 = std.math.maxInt(u64);
    for (counts) |c| {
        if (c == 0) continue;
        most = @max(most, c);
        least = @min(least, c);
    }
    print("part 2: {d}\n", .{most - least});
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
