const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day24.txt");

const Block = struct {
    div: i64 = 1,
    add_x: i64 = 0, // "add x N" after "mod x 26"
    add_y: i64 = 0, // last "add y N"
};

/// Transition for the standard MONAD block:
///   x = z % 26 + add_x
///   z = z / div
///   if (w != x) z = z * 26 + w + add_y
fn applyBlock(b: Block, z_in: i64, w: i64) i64 {
    const x = @mod(z_in, 26) + b.add_x;
    var z = @divTrunc(z_in, b.div);
    if (w != x) {
        z = z * 26 + w + b.add_y;
    }
    return z;
}

fn parseBlocks() ![]Block {
    var blocks: List(Block) = .empty;
    errdefer blocks.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    var cur = Block{};
    var started = false;
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "inp ")) {
            if (started) {
                try blocks.append(gpa, cur);
            }
            cur = Block{};
            started = true;
        } else if (std.mem.startsWith(u8, line, "div z ")) {
            cur.div = try parseInt(i64, line[6..], 10);
        } else if (std.mem.startsWith(u8, line, "add x ")) {
            if (parseInt(i64, line[6..], 10)) |v| {
                cur.add_x = v; // keep the LAST numeric one (after mod x 26)
            } else |_| {}
        } else if (std.mem.startsWith(u8, line, "add y ")) {
            if (parseInt(i64, line[6..], 10)) |v| {
                cur.add_y = v; // keep the LAST numeric one (the real B)
            } else |_| {}
        }
    }
    if (started) {
        try blocks.append(gpa, cur);
    }
    return blocks.toOwnedSlice(gpa);
}

fn solveModel(blocks: []const Block, comptime maximize: bool) !u64 {
    // level-by-level: z -> best prefix (max or min numeric prefix)
    var states = Map(i64, u64).init(gpa);
    defer states.deinit();
    try states.put(0, 0);

    var level: usize = 0;
    while (level < blocks.len) : (level += 1) {
        var next = Map(i64, u64).init(gpa);
        var it = states.iterator();
        while (it.next()) |e| {
            const z = e.key_ptr.*;
            const prefix = e.value_ptr.*;
            var digit: i64 = if (maximize) 9 else 1;
            const step: i64 = if (maximize) -1 else 1;
            while (digit >= 1 and digit <= 9) : (digit += step) {
                const d: u64 = @intCast(digit);
                const nz = applyBlock(blocks[level], z, @intCast(d));
                const np = prefix * 10 + d;
                const gop = try next.getOrPut(nz);
                if (!gop.found_existing) {
                    gop.value_ptr.* = np;
                } else if (maximize) {
                    gop.value_ptr.* = @max(gop.value_ptr.*, np);
                } else {
                    gop.value_ptr.* = @min(gop.value_ptr.*, np);
                }
            }
        }
        states.deinit();
        states = next;
    }

    var best: u64 = if (maximize) 0 else std.math.maxInt(u64);
    var it = states.iterator();
    while (it.next()) |e| {
        if (e.key_ptr.* == 0) {
            if (maximize) {
                best = @max(best, e.value_ptr.*);
            } else {
                best = @min(best, e.value_ptr.*);
            }
        }
    }
    return best;
}

pub fn main() !void {
    const blocks = try parseBlocks();
    defer gpa.free(blocks);
    if (blocks.len != 14) {
        print("unexpected block count: {d}\n", .{blocks.len});
        return;
    }
    print("part 1: {d}\n", .{try solveModel(blocks, true)});
    print("part 2: {d}\n", .{try solveModel(blocks, false)});
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
// Only unmodified days will be modified.
