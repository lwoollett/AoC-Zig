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

var name_of = StrMap(usize).init(std.heap.page_allocator);
var value_of: List(i64) = .empty; // literal value or -1
var lhs: List(usize) = .empty;
var rhs: List(usize) = .empty;
var ops: List(u8) = .empty;
var names: List([]const u8) = .empty;
var humn_idx: usize = 0;

fn evalMonkey(i: usize) i64 {
    if (i == humn_idx) return -1; // marker
    if (value_of.items[i] >= 0) return value_of.items[i];
    const a = evalMonkey(lhs.items[i]);
    const b = evalMonkey(rhs.items[i]);
    if (a == -1 or b == -1) return -1; // depends on humn
    return switch (ops.items[i]) {
        '+' => a + b,
        '-' => a - b,
        '*' => a * b,
        else => @divTrunc(a, b),
    };
}

/// Evaluate without the humn marker (used to solve for humn).
fn evalPlain(i: usize) i64 {
    if (value_of.items[i] >= 0) return value_of.items[i];
    const a = evalPlain(lhs.items[i]);
    const b = evalPlain(rhs.items[i]);
    return switch (ops.items[i]) {
        '+' => a + b,
        '-' => a - b,
        '*' => a * b,
        else => @divTrunc(a, b),
    };
}

/// Solve: subtree containing humn must equal `target`.
fn solveFor(i: usize, target: i64) i64 {
    if (i == humn_idx) return target;
    if (value_of.items[i] >= 0) return value_of.items[i];
    const left_depends = evalMonkey(lhs.items[i]) == -1;
    const known_side = if (left_depends) evalPlain(rhs.items[i]) else evalPlain(lhs.items[i]);
    const sub = if (left_depends) lhs.items[i] else rhs.items[i];
    switch (ops.items[i]) {
        '+' => return solveFor(sub, target - known_side),
        '-' => {
            if (left_depends) {
                return solveFor(sub, target + known_side);
            }
            return solveFor(sub, known_side - target);
        },
        '*' => return solveFor(sub, @divTrunc(target, known_side)),
        else => { // '/'
            if (left_depends) {
                return solveFor(sub, target * known_side);
            }
            return solveFor(sub, @divTrunc(known_side, target));
        },
    }
}

pub fn main() !void {
    {
        // pass 1: register every monkey name
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            const colon = indexOf(u8, line, ':').?;
            const name = try std.heap.page_allocator.dupe(u8, line[0..colon]);
            try name_of.put(name, names.items.len);
            try names.append(gpa, name);
        }
        // pass 2: fill values/ops (names all resolve now)
        var lines2 = tokenizeAny(u8, data, "\n");
        while (lines2.next()) |line| {
            const colon = indexOf(u8, line, ':').?;
            const rest = trim(u8, line[colon + 1 ..], " ");
            if (rest[0] >= '0' and rest[0] <= '9') {
                value_of.append(gpa, try parseInt(i64, rest, 10)) catch unreachable;
                lhs.append(gpa, 0) catch unreachable;
                rhs.append(gpa, 0) catch unreachable;
                ops.append(gpa, 0) catch unreachable;
            } else {
                var it = tokenizeSca(u8, rest, ' ');
                const a = it.next().?;
                const op = it.next().?[0];
                const b = it.next().?;
                value_of.append(gpa, -1) catch unreachable;
                lhs.append(gpa, name_of.get(a).?) catch unreachable;
                rhs.append(gpa, name_of.get(b).?) catch unreachable;
                ops.append(gpa, op) catch unreachable;
            }
        }
    }
    humn_idx = name_of.get("humn").?;
    const root = name_of.get("root").?;

    print("part 1: {d}\n", .{blk: {
        const h = humn_idx;
        humn_idx = std.math.maxInt(usize);
        const v = evalPlain(root);
        humn_idx = h;
        break :blk v;
    }});

    // part 2: root becomes equality; solve for humn
    ops.items[root] = '=';
    const left_depends = evalMonkey(lhs.items[root]) == -1;
    const known = if (left_depends) evalPlain(rhs.items[root]) else evalPlain(lhs.items[root]);
    const sub = if (left_depends) lhs.items[root] else rhs.items[root];
    print("part 2: {d}\n", .{solveFor(sub, known)});
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
