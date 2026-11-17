const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day15.txt");

const max_discs = 12;

const Disc = struct { positions: u64, start: u64 };

fn dropTime(discs: []const Disc) u64 {
    var t: u64 = 0;
    while (true) : (t += 1) {
        var ok = true;
        for (discs, 0..) |d, i| {
            // capsule reaches disc i (1-based) at t + i + 1
            if ((d.start + t + i + 1) % d.positions != 0) {
                ok = false;
                break;
            }
        }
        if (ok) return t;
    }
}

pub fn main() !void {
    var discs: [max_discs]Disc = undefined;
    var n: usize = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // Disc #1 has 13 positions; at time=0, it is at position 10.
        var it = tokenizeAny(u8, line, " ;#");
        _ = it.next().?; // Disc
        _ = it.next().?; // 1
        _ = it.next().?; // has
        const positions = try parseInt(u64, it.next().?, 10);
        _ = it.next().?; // positions
        _ = it.next().?; // at
        _ = it.next().?; // time=0
        _ = it.next().?; // it
        _ = it.next().?; // is
        _ = it.next().?; // at
        _ = it.next().?; // position
        const start = try parseInt(u64, trim(u8, it.next().?, "."), 10);
        discs[n] = .{ .positions = positions, .start = start };
        n += 1;
    }

    print("part 1: {d}\n", .{dropTime(discs[0..n])});

    // part 2: an extra disc with 11 positions at position 0
    discs[n] = .{ .positions = 11, .start = 0 };
    n += 1;
    print("part 2: {d}\n", .{dropTime(discs[0..n])});
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
