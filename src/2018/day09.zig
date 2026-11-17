const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day09.txt");

fn play(players: usize, last_marble: u64) u64 {
    const scores = gpa.alloc(u64, players) catch return 0;
    defer gpa.free(scores);
    @memset(scores, 0);

    // circle as a doubly-linked list over an array
    const next = gpa.alloc(u64, last_marble + 2) catch return 0;
    defer gpa.free(next);
    const prev = gpa.alloc(u64, last_marble + 2) catch return 0;
    defer gpa.free(prev);

    next[0] = 0;
    prev[0] = 0;
    var current: u64 = 0;

    var marble: u64 = 1;
    while (marble <= last_marble) : (marble += 1) {
        if (marble % 23 == 0) {
            const player = marble % players;
            scores[player] += marble;
            var c = current;
            var i: u32 = 0;
            while (i < 7) : (i += 1) c = prev[c];
            // remove c
            next[prev[c]] = next[c];
            prev[next[c]] = prev[c];
            scores[player] += c;
            current = next[c];
        } else {
            // insert after next[current]
            const a = next[current];
            const b = next[a];
            next[marble] = b;
            prev[marble] = a;
            next[a] = marble;
            prev[b] = marble;
            current = marble;
        }
    }

    var best: u64 = 0;
    for (scores) |s| best = @max(best, s);
    return best;
}

pub fn main() !void {
    // "448 players; last marble is worth 71628 points" — take the two integers.
    var nums: [2]usize = undefined;
    var n: usize = 0;
    var it = tokenizeAny(u8, data, " ;\n");
    while (it.next()) |tok| {
        if (n >= 2) break;
        if (parseInt(usize, tok, 10)) |v| {
            nums[n] = v;
            n += 1;
        } else |_| {}
    }
    const players = nums[0];
    const last = nums[1];

    print("part 1: {d}\n", .{play(players, @intCast(last))});
    print("part 2: {d}\n", .{play(players, @intCast(last * 100))});
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
