const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day21.txt");

const Regs = [6]u64;

fn apply(op: u8, r: Regs, a: u64, b: u64, c: u64) Regs {
    var n = r;
    switch (op) {
        0 => n[c] = n[a] + n[b],
        1 => n[c] = n[a] + b,
        2 => n[c] = n[a] * n[b],
        3 => n[c] = n[a] * b,
        4 => n[c] = n[a] & n[b],
        5 => n[c] = n[a] & b,
        6 => n[c] = n[a] | n[b],
        7 => n[c] = n[a] | b,
        8 => n[c] = n[a],
        9 => n[c] = a,
        10 => n[c] = if (a > n[b]) 1 else 0,
        11 => n[c] = if (n[a] > b) 1 else 0,
        12 => n[c] = if (n[a] > n[b]) 1 else 0,
        13 => n[c] = if (a == n[b]) 1 else 0,
        14 => n[c] = if (n[a] == b) 1 else 0,
        15 => n[c] = if (n[a] == n[b]) 1 else 0,
        else => unreachable,
    }
    return n;
}

pub fn main() !void {
    var ip_reg: u3 = 0;
    var ops: [64]u8 = @splat(0);
    var aa: [64]u64 = @splat(0);
    var bb: [64]u64 = @splat(0);
    var cc: [64]u64 = @splat(0);
    var n_ins: usize = 0;

    const names = [_][]const u8{ "addr", "addi", "mulr", "muli", "banr", "bani", "borr", "bori", "setr", "seti", "gtir", "gtri", "gtrr", "eqir", "eqri", "eqrr" };

    var lines = tokenizeAny(u8, data, "\n");
    const first = lines.next().?;
    ip_reg = @intCast(try parseInt(u8, first[4..], 10));

    var seed: u64 = 0;
    var mult: u64 = 0;
    var prev_was_bori_r3: bool = false;
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, " ");
        const opname = it.next().?;
        var op: u8 = 0;
        for (names, 0..) |nm, i| {
            if (std.mem.eql(u8, nm, opname)) op = @intCast(i);
        }
        ops[n_ins] = op;
        aa[n_ins] = try parseInt(u64, it.next().?, 10);
        bb[n_ins] = try parseInt(u64, it.next().?, 10);
        cc[n_ins] = try parseInt(u64, it.next().?, 10);

        // the generator: bori 3 65536 2; seti SEED . 3 ...; muli 3 MULT 3
        if (op == 7 and aa[n_ins] == 3 and bb[n_ins] == 65536) prev_was_bori_r3 = true;
        if (prev_was_bori_r3 and op == 9 and cc[n_ins] == 3) {
            seed = aa[n_ins];
            prev_was_bori_r3 = false;
        }
        if (op == 3 and aa[n_ins] == 3) mult = bb[n_ins];
        n_ins += 1;
    }
    if (ip_reg > 5) return error.BadIp;
    if (seed == 0 or mult == 0) return error.NoGenerator;

    // Native F: fold (x | 65536) bytes through h = ((h + byte) * mult) % 2^24.
    const F = struct {
        fn f(x: u64, s: u64, m: u64) u64 {
            var h: u64 = s;
            var y: u64 = x | 65536;
            while (y != 0) {
                h = ((h + (y & 255)) * m) & 16777215;
                y >>= 8;
            }
            return h;
        }
    }.f;

    // The program halts when r0 equals the compared value; the fewest-steps
    // halt uses the LAST value of the sequence before it first repeats.
    var seen = Map(u64, void).init(gpa);
    defer seen.deinit();
    var v: u64 = 872; // value at the first compare with r0 = 0 (from the prologue)
    // NOTE: compute the true first compared value by running the prologue's
    // arithmetic: 123 & 456 == 72 gates a jump; with r0=0 the prologue falls
    // through to the generator seeded from r3=0.
    v = F(0, seed, mult);
    var prev: u64 = v;
    while (!seen.contains(v)) {
        try seen.put(v, {});
        prev = v;
        v = F(v, seed, mult);
    }
    print("part 1: {d}\n", .{prev});
}

var last_compared: u64 = 0;

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
