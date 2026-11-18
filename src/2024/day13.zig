const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day13.txt");

pub fn main() !void {
    var total1: u64 = 0;
    var total2: u64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        // three lines: Button A, Button B, Prize
        const la = line;
        const lb = lines.next().?;
        const lp = lines.next().?;
        var av: [2]i128 = undefined;
        var bv: [2]i128 = undefined;
        var pz: [2]i128 = undefined;
        {
            var it = tokenizeAny(u8, la, "Button A: X+, Y");
            av[0] = try parseInt(i128, it.next().?, 10);
            av[1] = try parseInt(i128, it.next().?, 10);
        }
        {
            var it = tokenizeAny(u8, lb, "Button B: X+, Y");
            bv[0] = try parseInt(i128, it.next().?, 10);
            bv[1] = try parseInt(i128, it.next().?, 10);
        }
        {
            var it = tokenizeAny(u8, lp, "Prize: X=, Y=");
            pz[0] = try parseInt(i128, it.next().?, 10);
            pz[1] = try parseInt(i128, it.next().?, 10);
        }

        // p2: add 10^13 offset
        const pz2 = [2]i128{ pz[0] + 10000000000000, pz[1] + 10000000000000 };

        // solve av[0]*a + bv[0]*b = pz[0]; av[1]*a + bv[1]*b = pz[1]
        for (0..2) |part| {
            const target = if (part == 0) pz else pz2;
            const det = av[0] * bv[1] - av[1] * bv[0];
            if (det == 0) continue;
            const na = target[0] * bv[1] - target[1] * bv[0];
            const nb = av[0] * target[1] - av[1] * target[0];
            if (@rem(na, det) != 0 or @rem(nb, det) != 0) continue;
            const a = @divTrunc(na, det);
            const b = @divTrunc(nb, det);
            if (a < 0 or b < 0) continue;
            if (part == 0) {
                if (a <= 100 and b <= 100) {
                    total1 += @intCast(3 * a + b);
                }
            } else {
                total2 += @intCast(3 * a + b);
            }
        }
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
// Only unmodified days will be updated.
