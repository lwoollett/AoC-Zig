const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day05.txt");

pub fn main() !void {
    var stacks1: [9]List(u8) = @splat(.empty);
    var stacks2: [9]List(u8) = @splat(.empty);
    defer for (&stacks1) |*s| s.deinit(gpa);
    defer for (&stacks2) |*s| s.deinit(gpa);

    var lines = splitSca(u8, data, '\n');
    var in_moves = false;
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) {
            in_moves = true;
            continue;
        }
        if (!in_moves) {
            // stack line: keep leading spaces (they encode empty stacks!)
            const raw = trimRight(u8, line_raw, " \r");
            if (indexOf(u8, raw, '[') == null) continue; // the 1/2/3 numbering line
            for (0..9) |i| {
                const idx = 1 + i * 4;
                if (idx < raw.len and raw[idx] != ' ') {
                    try stacks1[i].insert(gpa, 0, raw[idx]);
                    try stacks2[i].insert(gpa, 0, raw[idx]);
                }
            }
            continue;
        }
        // "move N from A to B"
        var it = tokenizeAny(u8, line, "movefromto ");
        const n = try parseInt(u32, it.next().?, 10);
        const from = try parseInt(u32, it.next().?, 10) - 1;
        const to = try parseInt(u32, it.next().?, 10) - 1;

        // part 1: one at a time
        for (0..n) |_| {
            const c = stacks1[from].pop().?;
            try stacks1[to].append(gpa, c);
        }
        // part 2: all at once
        const from_len = stacks2[from].items.len;
        const chunk = stacks2[from].items[from_len - n ..];
        try stacks2[to].appendSlice(gpa, chunk);
        stacks2[from].shrinkRetainingCapacity(from_len - n);
    }

    print("part 1: ", .{});
    for (&stacks1) |*s| {
        if (s.items.len > 0) print("{c}", .{s.items[s.items.len - 1]});
    }
    print("\n", .{});
    print("part 2: ", .{});
    for (&stacks2) |*s| {
        if (s.items.len > 0) print("{c}", .{s.items[s.items.len - 1]});
    }
    print("\n", .{});
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
const trimRight = std.mem.trimEnd;
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
