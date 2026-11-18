const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day11.txt");

const Monkey = struct {
    items: List(u64) = .empty,
    op: u8 = '+', // '+', '*', or 's' for square
    operand: u64 = 0,
    divisor: u64 = 1,
    true_target: usize = 0,
    false_target: usize = 0,
    inspections: u64 = 0,
};

pub fn main() !void {
    var monkeys: List(Monkey) = .empty;
    defer monkeys.deinit(gpa);

    {
        var lines = tokenizeAny(u8, data, "\n");
        var cur = Monkey{};
        var have = false;
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "Monkey")) {
                if (have) {
                    try monkeys.append(gpa, cur);
                    cur = Monkey{};
                }
                have = true;
            } else if (std.mem.startsWith(u8, line, "  Starting items:")) {
                var it = tokenizeAny(u8, line[17..], ", ");
                while (it.next()) |tok| {
                    try cur.items.append(gpa, try parseInt(u64, tok, 10));
                }
            } else if (std.mem.startsWith(u8, line, "  Operation:")) {
                // new = old <op> <operand>
                const tail = line[23];
                cur.op = tail;
                if (tail == '*') {
                    const rhs = line[25..];
                    if (rhs[0] == 'o') {
                        cur.op = 's';
                        cur.operand = 0;
                    } else {
                        cur.operand = try parseInt(u64, rhs, 10);
                    }
                } else {
                    cur.operand = try parseInt(u64, line[25..], 10);
                }
            } else if (std.mem.startsWith(u8, line, "  Test: divisible by ")) {
                cur.divisor = try parseInt(u64, line[21..], 10);
            } else if (std.mem.startsWith(u8, line, "    If true: throw to monkey ")) {
                cur.true_target = try parseInt(usize, line[29..], 10);
            } else if (std.mem.startsWith(u8, line, "    If false: throw to monkey ")) {
                cur.false_target = try parseInt(usize, line[30..], 10);
            }
        }
        if (have) {
            try monkeys.append(gpa, cur);
        }
    }

    // LCM modulus for part 2
    var modulus: u64 = 1;
    for (monkeys.items) |m| {
        modulus *= m.divisor;
    }

    // part 1: 20 rounds, /3
    {
        for (0..20) |_| {
            for (monkeys.items) |*m| {
                for (m.items.items) |item| {
                    m.inspections += 1;
                    var v = applyOp(m, item) / 3;
                    v %= modulus;
                    const target = if (v % m.divisor == 0) m.true_target else m.false_target;
                    try monkeys.items[target].items.append(gpa, v);
                }
                m.items.clearRetainingCapacity();
            }
        }
        var counts: List(u64) = .empty;
        defer counts.deinit(gpa);
        for (monkeys.items, 0..) |m, mi| {
            try counts.append(gpa, m.inspections);
            monkeys.items[mi].inspections = 0;
            monkeys.items[mi].items.clearRetainingCapacity();
        }
        std.mem.sort(u64, counts.items, {}, comptime std.sort.desc(u64));
        print("part 1: {d}\n", .{counts.items[0] * counts.items[1]});
    }

    // reset items by re-parsing
    {
        monkeys.clearRetainingCapacity();
        var lines = tokenizeAny(u8, data, "\n");
        var cur = Monkey{};
        var have = false;
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "Monkey")) {
                if (have) {
                    try monkeys.append(gpa, cur);
                    cur = Monkey{};
                }
                have = true;
            } else if (std.mem.startsWith(u8, line, "  Starting items:")) {
                var it = tokenizeAny(u8, line[17..], ", ");
                while (it.next()) |tok| {
                    try cur.items.append(gpa, try parseInt(u64, tok, 10));
                }
            } else if (std.mem.startsWith(u8, line, "  Operation:")) {
                const tail = line[23];
                cur.op = tail;
                if (tail == '*') {
                    const rhs = line[25..];
                    if (rhs[0] == 'o') {
                        cur.op = 's';
                    } else {
                        cur.operand = try parseInt(u64, rhs, 10);
                    }
                } else {
                    cur.operand = try parseInt(u64, line[25..], 10);
                }
            } else if (std.mem.startsWith(u8, line, "  Test: divisible by ")) {
                cur.divisor = try parseInt(u64, line[21..], 10);
            } else if (std.mem.startsWith(u8, line, "    If true: throw to monkey ")) {
                cur.true_target = try parseInt(usize, line[29..], 10);
            } else if (std.mem.startsWith(u8, line, "    If false: throw to monkey ")) {
                cur.false_target = try parseInt(usize, line[30..], 10);
            }
        }
        if (have) {
            try monkeys.append(gpa, cur);
        }
    }

    // part 2: 10000 rounds, mod lcm
    {
        for (0..10000) |_| {
            for (monkeys.items) |*m| {
                for (m.items.items) |item| {
                    m.inspections += 1;
                    const v = applyOp(m, item) % modulus;
                    const target = if (v % m.divisor == 0) m.true_target else m.false_target;
                    try monkeys.items[target].items.append(gpa, v);
                }
                m.items.clearRetainingCapacity();
            }
        }
        var counts: List(u64) = .empty;
        defer counts.deinit(gpa);
        for (monkeys.items) |m| {
            try counts.append(gpa, m.inspections);
        }
        std.mem.sort(u64, counts.items, {}, comptime std.sort.desc(u64));
        print("part 2: {d}\n", .{counts.items[0] * counts.items[1]});
    }
}

fn applyOp(m: *const Monkey, old: u64) u64 {
    return switch (m.op) {
        '+' => old + m.operand,
        '*' => old * m.operand,
        else => old * old, // square
    };
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
