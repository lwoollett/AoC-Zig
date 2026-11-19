const std = @import("std");
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day16.txt");

const n_progs = 16;

fn dance(progs: *[n_progs]u8, moves: [][]const u8) void {
    for (moves) |move| {
        switch (move[0]) {
            's' => {
                const count = parseInt(usize, move[1..], 10) catch 0;
                var tmp: [n_progs]u8 = undefined;
                for (progs, 0..) |c, i| {
                    tmp[(i + count) % n_progs] = c;
                }
                progs.* = tmp;
            },
            'x' => {
                // xA/B
                var it = tokenizeAny(u8, move[1..], "/");
                const a = parseInt(usize, it.next().?, 10) catch 0;
                const b = parseInt(usize, it.next().?, 10) catch 0;
                std.mem.swap(u8, &progs[a], &progs[b]);
            },
            'p' => {
                // pA/B
                const a = std.mem.findScalar(u8, progs, move[1]).?;
                const b = std.mem.findScalar(u8, progs, move[3]).?;
                std.mem.swap(u8, &progs[a], &progs[b]);
            },
            else => {},
        }
    }
}

pub fn main() !void {
    var moves: List([]const u8) = .empty;
    defer moves.deinit(gpa);
    var it = tokenizeAny(u8, data, ",\n");
    while (it.next()) |m| {
        try moves.append(gpa, m);
    }

    var progs: [n_progs]u8 = undefined;
    for (&progs, 0..) |*p, i| p.* = @intCast('a' + i);

    // part 1
    dance(&progs, moves.items);
    print("part 1: {s}\n", .{progs});

    // part 2: find the cycle length of repeated dances, then fast-forward.
    for (&progs, 0..) |*p, i| p.* = @intCast('a' + i);
    var seen = StrMap(u64).init(gpa);
    defer {
        var kit = seen.keyIterator();
        while (kit.next()) |k| gpa.free(k.*);
        seen.deinit();
    }
    var round: u64 = 0;
    var cycle: u64 = 0;
    while (round < 1_000_000_000) : (round += 1) {
        var buf: [n_progs]u8 = undefined;
        @memcpy(&buf, &progs);
        const key = try gpa.dupe(u8, &buf);
        if (seen.get(key)) |first| {
            cycle = round - first;
            // fast-forward: we are at state S(round); S repeats every `cycle`.
            const remaining = (1_000_000_000 - round) % cycle;
            var r: u64 = 0;
            while (r < remaining) : (r += 1) {
                dance(&progs, moves.items);
            }
            print("part 2: {s}\n", .{progs});
            return;
        }
        try seen.put(key, round);
        dance(&progs, moves.items);
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
