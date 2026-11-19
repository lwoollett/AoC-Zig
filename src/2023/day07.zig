const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day07.txt");

const Hand = struct {
    cards: [5]u8,
    bid: u64,
    type: u32,
};

fn cardValue(c: u8, jokers: bool) u32 {
    if (c >= '2' and c <= '9') return c - '0';
    return switch (c) {
        'T' => 10,
        'J' => if (jokers) 1 else 11,
        'Q' => 12,
        'K' => 13,
        else => 14,
    };
}

fn handType(cards: [5]u8, jokers: bool) u32 {
    var counts: [15]u32 = @splat(0);
    for (cards) |c| {
        counts[cardValue(c, jokers)] += 1;
    }
    var jc: u32 = 0;
    if (jokers) {
        jc = counts[1];
        counts[1] = 0;
    }
    // sort counts desc
    std.mem.sort(u32, counts[2..], {}, comptime std.sort.desc(u32));
    const best = counts[2] + jc;
    const second = counts[3];
    if (best == 5) return 7;
    if (best == 4) return 6;
    if (best == 3 and second == 2) return 5;
    if (best == 3) return 4;
    if (best == 2 and second == 2) return 3;
    if (best == 2) return 2;
    return 1;
}

fn handLess(comptime jokers: bool) fn (void, Hand, Hand) bool {
    return struct {
        fn lessThan(_: void, a: Hand, b: Hand) bool {
            if (a.type != b.type) return a.type < b.type;
            for (a.cards, b.cards) |ca, cb| {
                const va = cardValue(ca, jokers);
                const vb = cardValue(cb, jokers);
                if (va != vb) return va < vb;
            }
            return false;
        }
    }.lessThan;
}

fn totalWinnings(comptime jokers: bool) !u64 {
    var hands: List(Hand) = .empty;
    defer hands.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var h = Hand{ .cards = undefined, .bid = 0, .type = 0 };
        @memcpy(&h.cards, line[0..5]);
        h.bid = try parseInt(u64, line[6..], 10);
        h.type = handType(h.cards, jokers);
        try hands.append(gpa, h);
    }
    std.mem.sort(Hand, hands.items, {}, handLess(jokers));
    var total: u64 = 0;
    for (hands.items, 0..) |h, i| {
        total += h.bid * (i + 1);
    }
    return total;
}

pub fn main() !void {
    print("part 1: {d}\n", .{try totalWinnings(false)});
    print("part 2: {d}\n", .{try totalWinnings(true)});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
