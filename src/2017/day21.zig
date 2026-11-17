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

const stride = 2304; // 18 iterations ends at size 2187

const BigGrid = struct {
    size: usize,
    cells: []u8, // stride x stride

    fn init() !BigGrid {
        return .{ .size = 0, .cells = try gpa.alloc(u8, stride * stride) };
    }
    fn at(self: *const BigGrid, y: usize, x: usize) u8 {
        return self.cells[y * stride + x];
    }
    fn set(self: *BigGrid, y: usize, x: usize, v: u8) void {
        self.cells[y * stride + x] = v;
    }
};

/// Small pattern (max 4x4) with its size.
const Pat = struct { size: usize, cells: [16]u8 };

fn parsePat(s: []const u8) Pat {
    var p = Pat{ .size = 0, .cells = @splat(0) };
    var y: usize = 0;
    var it = tokenizeSca(u8, s, '/');
    while (it.next()) |row| {
        p.size = row.len;
        for (row, 0..) |c, x| {
            p.cells[y * 4 + x] = if (c == '#') 1 else 0;
        }
        y += 1;
    }
    return p;
}

/// key: pattern bits under the given flip/rot, n x n
fn keyOfPat(p: *const Pat, flip: usize, rot: usize) u32 {
    const n = p.size;
    var k: u32 = 0;
    var i: u32 = 0;
    for (0..n) |y| {
        for (0..n) |x| {
            var yy = y;
            var xx = x;
            if (flip & 1 != 0) xx = n - 1 - xx;
            if (flip & 2 != 0) yy = n - 1 - yy;
            var r = rot;
            while (r > 0) : (r -= 1) {
                const t = xx;
                xx = n - 1 - yy;
                yy = t;
            }
            if (p.cells[yy * 4 + xx] == 1) k |= @as(u32, 1) << @intCast(i);
            i += 1;
        }
    }
    return k;
}

/// key of an n x n region of a big grid
fn keyOfRegion(g: *const BigGrid, oy: usize, ox: usize, n: usize, flip: usize, rot: usize) u32 {
    var p = Pat{ .size = n, .cells = @splat(0) };
    for (0..n) |y| {
        for (0..n) |x| {
            p.cells[y * 4 + x] = g.at(oy + y, ox + x);
        }
    }
    return keyOfPat(&p, flip, rot);
}

fn enhance(g: *const BigGrid, out: *BigGrid, rules2: *Map(u32, Pat), rules3: *Map(u32, Pat)) !void {
    const sub = if (g.size % 2 == 0) @as(usize, 2) else 3;
    const dst = sub + 1;
    out.size = g.size / sub * dst;
    for (0..g.size / sub) |by| {
        for (0..g.size / sub) |bx| {
            var found: ?Pat = null;
            var flip: usize = 0;
            while (flip < 4) : (flip += 1) {
                var rot: usize = 0;
                while (rot < 4) : (rot += 1) {
                    const k = keyOfRegion(g, by * sub, bx * sub, sub, flip, rot);
                    const rules = if (sub == 2) rules2 else rules3;
                    if (rules.get(k)) |r| {
                        found = r;
                        break;
                    }
                }
                if (found != null) break;
            }
            const r = found orelse return error.NoRule;
            for (0..dst) |y| {
                for (0..dst) |x| {
                    out.set(by * dst + y, bx * dst + x, r.cells[y * 4 + x]);
                }
            }
        }
    }
}

pub fn main() !void {
    var rules2 = Map(u32, Pat).init(gpa);
    defer rules2.deinit();
    var rules3 = Map(u32, Pat).init(gpa);
    defer rules3.deinit();

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const arrow = std.mem.find(u8, line, "=>").?;
        const in_p = parsePat(trim(u8, line[0..arrow], " "));
        const out_p = parsePat(trim(u8, line[arrow + 2 ..], " "));
        var flip: usize = 0;
        while (flip < 4) : (flip += 1) {
            var rot: usize = 0;
            while (rot < 4) : (rot += 1) {
                const k = keyOfPat(&in_p, flip, rot);
                if (in_p.size == 2) {
                    try rules2.put(k, out_p);
                } else {
                    try rules3.put(k, out_p);
                }
            }
        }
    }

    var grids = [2]BigGrid{ try BigGrid.init(), try BigGrid.init() };
    defer gpa.free(grids[0].cells);
    defer gpa.free(grids[1].cells);

    // seed .#./..#/###
    grids[0].size = 3;
    @memset(grids[0].cells, 0);
    grids[0].set(0, 1, 1);
    grids[0].set(1, 0, 1);
    grids[0].set(2, 2, 1);
    grids[0].set(2, 1, 1);
    grids[0].set(2, 0, 1);

    var cur: usize = 0;
    var iter: usize = 0;
    while (iter < 18) : (iter += 1) {
        @memset(grids[1 - cur].cells, 0);
        try enhance(&grids[cur], &grids[1 - cur], &rules2, &rules3);
        cur = 1 - cur;
        if (iter == 4 or iter == 17) {
            var count: u32 = 0;
            const g = &grids[cur];
            for (0..g.size) |y| {
                for (0..g.size) |x| {
                    count += g.at(y, x);
                }
            }
            if (iter == 4) {
                print("part 1: {d}\n", .{count});
            } else {
                print("part 2: {d}\n", .{count});
            }
        }
    }
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
