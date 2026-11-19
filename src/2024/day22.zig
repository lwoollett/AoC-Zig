const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
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
    // base-19 packing: deltas are -9..9, so the key space is 19^4 = 130321 —
    // small enough to drive a flat seen-bitset
    return @intCast((a + 9) + 19 * ((b + 9) + 19 * ((c + 9) + 19 * (d + 9))));
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
    try best_prices.ensureTotalCapacity(140_000);

    // windows are 4 deltas in [-9,9]: a flat seen-bitset beats a hashmap
    // per buyer. seq_prices is hoisted and reused.
    var seen_local = try gpa.alloc(bool, 19 * 19 * 19 * 19);
    defer gpa.free(seen_local);
    var seq_prices: List(u64) = .empty;
    defer seq_prices.deinit(gpa);
    try seq_prices.ensureTotalCapacity(gpa, 2001);

    for (seqs.items) |seed| {
        var v = seed;
        seq_prices.clearRetainingCapacity();
        seq_prices.append(gpa, v % 10) catch unreachable;
        var i: usize = 0;
        while (i < 2000) : (i += 1) {
            v = nextSecret(v);
            seq_prices.append(gpa, v % 10) catch unreachable;
        }
        total_2000 += v;

        // first price per 4-window
        @memset(seen_local, false);
        for (4..seq_prices.items.len) |k| {
            const d1: i64 = @as(i64, @intCast(seq_prices.items[k - 3])) - @as(i64, @intCast(seq_prices.items[k - 4]));
            const d2: i64 = @as(i64, @intCast(seq_prices.items[k - 2])) - @as(i64, @intCast(seq_prices.items[k - 3]));
            const d3: i64 = @as(i64, @intCast(seq_prices.items[k - 1])) - @as(i64, @intCast(seq_prices.items[k - 2]));
            const d4: i64 = @as(i64, @intCast(seq_prices.items[k])) - @as(i64, @intCast(seq_prices.items[k - 1]));
            if (d1 < -9 or d1 > 9 or d2 < -9 or d2 > 9 or d3 < -9 or d3 > 9 or d4 < -9 or d4 > 9) continue;
            const key = packWindow(d1, d2, d3, d4);
            if (seen_local[@intCast(key)]) continue;
            seen_local[@intCast(key)] = true;
            const gop = best_prices.getOrPutAssumeCapacity(key);
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
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
