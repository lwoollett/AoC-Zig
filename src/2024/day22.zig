const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day22.txt");

const mask: u64 = 16777216 - 1;

fn nextSecret(v_in: u64) u64 {
    var v = v_in;
    v = ((v * 64) ^ v) & mask;
    v = ((v / 32) ^ v) & mask;
    v = ((v * 2048) ^ v) & mask;
    return v;
}

/// key: 4 consecutive diffs (each -9..9) packed
fn packWindow(a: i64, b: i64, c: i64, d: i64) u64 {
    return @bitCast((a + 9) << 24 | (b + 9) << 18 | (c + 9) << 12 | (d + 9) << 6);
}

pub fn main() !void {
    var seqs: List(u64) = .empty;
    defer seqs.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        try seqs.append(gpa, try parseInt(u64, line, 10));
    }

    var total_2000: u64 = 0;
    var best_prices = Map(u64, u64).init(gpa); // window -> sum of best prices per buyer
    defer best_prices.deinit();

    for (seqs.items) |seed| {
        var v = seed;
        var seq_prices: List(u64) = .empty;
        defer seq_prices.deinit(gpa);
        try seq_prices.append(gpa, v % 10);
        var i: usize = 0;
        while (i < 2000) : (i += 1) {
            v = nextSecret(v);
            try seq_prices.append(gpa, v % 10);
        }
        total_2000 += v;

        // first price per 4-window
        var seen_local = Map(u64, void).init(gpa);
        defer seen_local.deinit();
        for (4..seq_prices.items.len) |k| {
            const d1: i64 = @as(i64, @intCast(seq_prices.items[k - 3])) - @as(i64, @intCast(seq_prices.items[k - 4]));
            const d2: i64 = @as(i64, @intCast(seq_prices.items[k - 2])) - @as(i64, @intCast(seq_prices.items[k - 3]));
            const d3: i64 = @as(i64, @intCast(seq_prices.items[k - 1])) - @as(i64, @intCast(seq_prices.items[k - 2]));
            const d4: i64 = @as(i64, @intCast(seq_prices.items[k])) - @as(i64, @intCast(seq_prices.items[k - 1]));
            if (d1 < -9 or d1 > 9 or d2 < -9 or d2 > 9 or d3 < -9 or d3 > 9 or d4 < -9 or d4 > 9) continue;
            const key = packWindow(d1, d2, d3, d4);
            if (seen_local.contains(key)) continue;
            try seen_local.put(key, {});
            const gop = try best_prices.getOrPut(key);
            if (!gop.found_existing) gop.value_ptr.* = 0;
            gop.value_ptr.* += seq_prices.items[k];
        }
    }
    print("part 1: {d}\n", .{total_2000});

    var best: u64 = 0;
    var bit = best_prices.valueIterator();
    while (bit.next()) |v| {
        best = @max(best, v.*);
    }
    print("part 2: {d}\n", .{best});
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
