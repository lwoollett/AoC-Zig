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
    add_x: i64 = 0,
    add_y: i64 = 0,
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

const Entry = struct { z: i64, prefix: u64 };

/// Open-addressing dedup table (z >= 0 domain; -1 = empty).
const ZTable = struct {
    keys: []i64,
    vals: []u64,
    mask: usize,
    count: usize,

    fn init(alloc: Allocator, cap: usize) !ZTable {
        var size: usize = 1;
        while (size < cap * 2) size <<= 1;
        const keys = try alloc.alloc(i64, size);
        const vals = try alloc.alloc(u64, size);
        @memset(keys, -1);
        return .{ .keys = keys, .vals = vals, .mask = size - 1, .count = 0 };
    }

    fn deinit(self: *ZTable, alloc: Allocator) void {
        alloc.free(self.keys);
        alloc.free(self.vals);
    }

    /// keep the best prefix (max or min) per key; returns deduped entries
    fn insertAll(self: *ZTable, entries: []const Entry, comptime maximize: bool, out: *List(Entry)) !void {
        for (entries) |e| {
            var h: usize = @bitCast(@as(u64, @intCast(e.z)) *% 0x9E3779B97F4A7C15);
            h &= self.mask;
            while (true) {
                const k = self.keys[h];
                if (k == -1) {
                    self.keys[h] = e.z;
                    self.vals[h] = e.prefix;
                    try out.append(gpa, e);
                    self.count += 1;
                    break;
                }
                if (k == e.z) {
                    if ((maximize and e.prefix > self.vals[h]) or (!maximize and e.prefix < self.vals[h])) {
                        self.vals[h] = e.prefix;
                    }
                    break;
                }
                h = (h + 1) & self.mask;
            }
        }
        // second pass: write back the best prefixes to the out entries
        for (out.items) |*o| {
            var h: usize = @bitCast(@as(u64, @intCast(o.z)) *% 0x9E3779B97F4A7C15);
            h &= self.mask;
            while (self.keys[h] != o.z) h = (h + 1) & self.mask;
            o.prefix = self.vals[h];
        }
    }
};

fn solveModel(blocks: []const Block, comptime maximize: bool) !u64 {
    var states: List(Entry) = .empty;
    defer states.deinit(gpa);
    var next: List(Entry) = .empty;
    defer next.deinit(gpa);
    var raw: List(Entry) = .empty;
    defer raw.deinit(gpa);
    try states.append(gpa, .{ .z = 0, .prefix = 0 });

    for (blocks) |b| {
        raw.clearRetainingCapacity();
        for (states.items) |st| {
            var w: i64 = 1;
            while (w <= 9) : (w += 1) {
                try raw.append(gpa, .{ .z = applyBlock(b, st.z, w), .prefix = st.prefix * 10 + @as(u64, @intCast(w)) });
            }
        }
        var table = try ZTable.init(gpa, raw.items.len);
        defer table.deinit(gpa);
        next.clearRetainingCapacity();
        try table.insertAll(raw.items, maximize, &next);
        const tmp = states;
        states = next;
        next = tmp;
    }

    var best: ?u64 = null;
    for (states.items) |st| {
        if (st.z == 0) {
            if (best == null or (maximize and st.prefix > best.?) or (!maximize and st.prefix < best.?)) {
                best = st.prefix;
            }
        }
    }
    return best orelse error.NoSolution;
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
// Only unmodified days will be updated.
