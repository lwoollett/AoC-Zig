const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day19.txt");

const Regs = [6]u64;

fn apply(op: u8, r: Regs, a: u64, b: u64, c: u64) Regs {
    var n = r;
    switch (op) {
        0 => n[c] = n[a] + n[b], // addr
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

const Program = struct {
    ip_reg: u3,
    ops: [64]u8,
    a: [64]u64,
    b: [64]u64,
    c: [64]u64,
    n: usize,
};

fn parse() !Program {
    var p = Program{ .ip_reg = 0, .ops = @splat(0), .a = @splat(0), .b = @splat(0), .c = @splat(0), .n = 0 };
    var lines = tokenizeAny(u8, data, "\n");
    const first = lines.next().?; // "#ip 3"
    p.ip_reg = @intCast(try parseInt(u8, first[4..], 10));
    const names = [_][]const u8{ "addr", "addi", "mulr", "muli", "banr", "bani", "borr", "bori", "setr", "seti", "gtir", "gtri", "gtrr", "eqir", "eqri", "eqrr" };
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, " ");
        const opname = it.next().?;
        var op: u8 = 0;
        for (names, 0..) |nm, i| {
            if (std.mem.eql(u8, nm, opname)) op = @intCast(i);
        }
        p.ops[p.n] = op;
        p.a[p.n] = try parseInt(u64, it.next().?, 10);
        p.b[p.n] = try parseInt(u64, it.next().?, 10);
        p.c[p.n] = try parseInt(u64, it.next().?, 10);
        p.n += 1;
    }
    return p;
}

fn run(p: *const Program, r0: u64, max_steps: u64, stable_reg: ?*u64) u64 {
    var r = Regs{ r0, 0, 0, 0, 0, 0 };
    var ip: u64 = 0;
    var steps: u64 = 0;
    // snapshot machinery: register value stable for a long stretch
    var snap_values: [6]u64 = @splat(0);
    var snaps_taken: u64 = 0;
    while (ip < p.n) {
        r[p.ip_reg] = ip;
        r = apply(p.ops[ip], r, p.a[ip], p.b[ip], p.c[ip]);
        ip = r[p.ip_reg] + 1;
        steps += 1;
        if (stable_reg != null and steps % 500_000 == 0) {
            if (snaps_taken == 0) {
                snap_values = r;
            } else {
                for (r, 0..) |v, i| {
                    if (v != snap_values[i]) snap_values[i] = 0;
                }
            }
            snaps_taken += 1;
        }
        if (steps > max_steps) {
            if (stable_reg) |out| {
                var best: u64 = 0;
                for (snap_values) |v| {
                    if (v > 1000 and v > best) best = v;
                }
                out.* = best;
            }
            return r[0];
        }
    }
    return r[0];
}

fn sumDivisors(n: u64) u64 {
    var sum: u64 = 0;
    var d: u64 = 1;
    while (d * d <= n) : (d += 1) {
        if (n % d == 0) {
            sum += d;
            if (d != n / d) sum += n / d;
        }
    }
    return sum;
}

pub fn main() !void {
    const p = try parse();

    // Part 1: direct simulation.
    print("part 1: {d}\n", .{run(&p, 0, 10_000_000_000, null)});

    // Part 2: r0=1 makes the program compute the sum of divisors of a
    // large constant it builds in a register; extract it and shortcut.
    var target: u64 = 0;
    _ = run(&p, 1, 30_000_000, &target);
    if (target == 0) return error.NoTargetFound;
    print("part 2: {d}\n", .{sumDivisors(target)});
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
