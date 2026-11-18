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
    // vals[i] = index into the out list of the entry owning keys[i]
    vals: []usize,
    mask: usize,
    count: usize,

    fn init(alloc: Allocator, cap: usize) !ZTable {
        var size: usize = 1;
        while (size < cap * 2) size <<= 1;
        const keys = try alloc.alloc(i64, size);
        const vals = try alloc.alloc(usize, size);
        @memset(keys, -1);
        return .{ .keys = keys, .vals = vals, .mask = size - 1, .count = 0 };
    }

    fn deinit(self: *ZTable, alloc: Allocator) void {
        alloc.free(self.keys);
        alloc.free(self.vals);
    }

    /// keep the best prefix (max or min) per z; single pass, no raw list
    fn insertAll(self: *ZTable, entries: []const Entry, comptime maximize: bool, out: *List(Entry)) !void {
        for (entries) |e| {
            var h: usize = @bitCast(@as(u64, @intCast(e.z)) *% 0x9E3779B97F4A7C15);
            h &= self.mask;
            while (true) {
                const k = self.keys[h];
                if (k == -1) {
                    self.keys[h] = e.z;
                    self.vals[h] = out.items.len;
                    try out.append(gpa, e);
                    self.count += 1;
                    break;
                }
                if (k == e.z) {
                    const cur = &out.items[self.vals[h]];
                    if ((maximize and e.prefix > cur.prefix) or (!maximize and e.prefix < cur.prefix)) {
                        cur.prefix = e.prefix;
                    }
                    break;
                }
                h = (h + 1) & self.mask;
            }
        }
    }
};

fn solveModel(blocks: []const Block, comptime maximize: bool) !u64 {
    var states: List(Entry) = .empty;
    defer states.deinit(gpa);
    var next: List(Entry) = .empty;
    defer next.deinit(gpa);
    try states.append(gpa, .{ .z = 0, .prefix = 0 });

    // z can shrink at most 26x per remaining pop block (div 26), and pushes
    // only grow it — so z >= 26^pops_after can never reach 0. Prune those.
    var pops_after: [15]u32 = @splat(0);
    {
        var i: usize = blocks.len - 1;
        while (true) : (i -= 1) {
            pops_after[i] = pops_after[i + 1] + @intFromBool(blocks[i].div == 26);
            if (i == 0) break;
        }
    }
    var z_cap: [15]i64 = @splat(0);
    for (0..blocks.len + 1) |i| {
        var cap: i64 = 1;
        for (0..pops_after[i]) |_| cap *= 26;
        z_cap[i] = cap;
    }

    var table: ?ZTable = null;
    defer if (table) |*t| t.deinit(gpa);
    for (blocks, 0..) |b, bi| {
        if (table == null or table.?.mask + 1 < states.items.len * 9 * 2) {
            if (table) |*t| t.deinit(gpa);
            table = try ZTable.init(gpa, states.items.len * 9);
        } else {
            @memset(table.?.keys, -1);
            table.?.count = 0;
        }
        next.clearRetainingCapacity();
        for (states.items) |st| {
            var w: i64 = 1;
            while (w <= 9) : (w += 1) {
                const e = Entry{ .z = applyBlock(b, st.z, w), .prefix = st.prefix * 10 + @as(u64, @intCast(w)) };
                try table.?.insertAll(&.{e}, maximize, &next);
            }
        }
        // prune dead z values (can't divide down to 0 in remaining pops)
        const cap = z_cap[bi + 1];
        if (cap < (1 << 62)) {
            var w: usize = 0;
            for (states.items) |st| {
                if (st.z < cap) {
                    states.items[w] = st;
                    w += 1;
                }
            }
            states.shrinkRetainingCapacity(w);
        }
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
