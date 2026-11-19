const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day22.txt");

fn score(deck: []const u32) u64 {
    var total: u64 = 0;
    for (deck, 0..) |c, i| {
        total += @as(u64, c) * (deck.len - i);
    }
    return total;
}

/// Recursive combat; returns the winner (0 or 1).
fn play(d1: *List(u32), d2: *List(u32), seen: *Map(u64, void)) !u8 {
    while (d1.items.len > 0 and d2.items.len > 0) {
        var h = std.hash.Wyhash.init(0);
        h.update(std.mem.sliceAsBytes(&[_]u32{0xDEAD}));
        h.update(std.mem.sliceAsBytes(d1.items));
        h.update(std.mem.sliceAsBytes(&[_]u32{0xBEEF}));
        h.update(std.mem.sliceAsBytes(d2.items));
        const key = h.final();
        if (seen.contains(key)) return 0; // player 1 wins loop
        try seen.put(key, {});

        const c1 = d1.orderedRemove(0);
        const c2 = d2.orderedRemove(0);

        var winner: u8 = undefined;
        if (d1.items.len >= c1 and d2.items.len >= c2) {
            // sub-game with copies
            var arena = std.heap.ArenaAllocator.init(gpa);
            defer arena.deinit();
            const a = arena.allocator();
            var s1: List(u32) = .empty;
            var s2: List(u32) = .empty;
            try s1.appendSlice(a, d1.items[0..c1]);
            try s2.appendSlice(a, d2.items[0..c2]);
            var sub_seen = Map(u64, void).init(a);
            winner = try play(&s1, &s2, &sub_seen);
        } else {
            winner = if (c1 > c2) 0 else 1;
        }

        if (winner == 0) {
            try d1.append(gpa, c1);
            try d1.append(gpa, c2);
        } else {
            try d2.append(gpa, c2);
            try d2.append(gpa, c1);
        }
    }
    return if (d1.items.len > 0) 0 else 1;
}

pub fn main() !void {
    var decks: [2]List(u32) = .{ .empty, .empty };
    defer for (&decks) |*d| d.deinit(gpa);
    {
        var player: usize = 0;
        var lines = splitSca(u8, data, '\n');
        while (lines.next()) |line_raw| {
            const line = trim(u8, line_raw, " \r");
            if (std.mem.startsWith(u8, line, "Player")) {
                if (std.mem.startsWith(u8, line, "Player 2")) player = 1;
                continue;
            }
            if (line.len == 0) continue;
            try decks[player].append(gpa, try parseInt(u32, line, 10));
        }
    }

    // part 1
    {
        var d1: List(u32) = .empty;
        defer d1.deinit(gpa);
        var d2: List(u32) = .empty;
        defer d2.deinit(gpa);
        try d1.appendSlice(gpa, decks[0].items);
        try d2.appendSlice(gpa, decks[1].items);
        while (d1.items.len > 0 and d2.items.len > 0) {
            const a = d1.orderedRemove(0);
            const b = d2.orderedRemove(0);
            if (a > b) {
                try d1.append(gpa, a);
                try d1.append(gpa, b);
            } else {
                try d2.append(gpa, b);
                try d2.append(gpa, a);
            }
        }
        const winner = if (d1.items.len > 0) d1.items else d2.items;
        print("part 1: {d}\n", .{score(winner)});
    }

    // part 2
    {
        var d1: List(u32) = .empty;
        defer d1.deinit(gpa);
        var d2: List(u32) = .empty;
        defer d2.deinit(gpa);
        try d1.appendSlice(gpa, decks[0].items);
        try d2.appendSlice(gpa, decks[1].items);
        var seen = Map(u64, void).init(gpa);
        defer seen.deinit();
        _ = try play(&d1, &d2, &seen);
        const winner = if (d1.items.len > 0) d1.items else d2.items;
        print("part 2: {d}\n", .{score(winner)});
    }
}

// Useful stdlib functions
const splitSca = std.mem.splitScalar;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
