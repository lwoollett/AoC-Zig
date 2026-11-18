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

const V3 = [3]i64;

const Scanner = struct {
    beacons: List(V3) = .empty,
    // after placement:
    pos: ?V3 = null,
    rot: usize = 0, // index into rotations applied to raw beacons
};

var scanners: List(Scanner) = .empty;

/// 24 proper rotations of 3D space.
const rotations = blk: {
    var rots: [24][9]i64 = undefined;
    var count: usize = 0;
    // all 3x3 matrices with entries from {-1,0,1}, one nonzero per row/col
    const perms = [_][3]usize{
        .{ 0, 1, 2 }, .{ 0, 2, 1 }, .{ 1, 0, 2 }, .{ 1, 2, 0 }, .{ 2, 0, 1 }, .{ 2, 1, 0 },
    };
    const signs = [_][3]i64{
        .{ 1, 1, 1 },  .{ 1, 1, -1 },  .{ 1, -1, 1 },  .{ 1, -1, -1 },
        .{ -1, 1, 1 }, .{ -1, 1, -1 }, .{ -1, -1, 1 }, .{ -1, -1, -1 },
    };
    for (perms) |pm| {
        for (signs) |sg| {
            var m = [9]i64{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };
            for (0..3) |row| {
                m[row * 3 + pm[row]] = sg[row];
            }
            // determinant must be +1 (proper rotation)
            const det = m[0] * (m[4] * m[8] - m[5] * m[7]) -
                m[1] * (m[3] * m[8] - m[5] * m[6]) +
                m[2] * (m[3] * m[7] - m[4] * m[6]);
            if (det == 1) {
                rots[count] = m;
                count += 1;
            }
        }
    }
    break :blk .{ .count = count, .rots = rots };
};

fn applyRot(m: *const [9]i64, v: V3) V3 {
    return .{
        m[0] * v[0] + m[1] * v[1] + m[2] * v[2],
        m[3] * v[0] + m[4] * v[1] + m[5] * v[2],
        m[6] * v[0] + m[7] * v[1] + m[8] * v[2],
    };
}

/// beacons of scanner i transformed into world coordinates (scanner placed)
fn worldBeacons(i: usize, out: *List(V3)) !void {
    const s = &scanners.items[i];
    const m: [9]i64 = rotations.rots[s.rot];
    for (s.beacons.items) |b| {
        const r = applyRot(&m, b);
        try out.append(gpa, .{ r[0] + s.pos.?[0], r[1] + s.pos.?[1], r[2] + s.pos.?[2] });
    }
}

pub fn main() !void {
    // parse scanners
    {
        var lines = tokenizeAny(u8, data, "\n");
        var cur = Scanner{};
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "---")) {
                if (cur.beacons.items.len > 0) {
                    try scanners.append(gpa, cur);
                    cur = Scanner{};
                }
                continue;
            }
            if (line.len == 0) continue;
            var it = tokenizeSca(u8, line, ',');
            const x = try parseInt(i64, it.next().?, 10);
            const y = try parseInt(i64, it.next().?, 10);
            const z = try parseInt(i64, it.next().?, 10);
            try cur.beacons.append(gpa, .{ x, y, z });
        }
        if (cur.beacons.items.len > 0) {
            try scanners.append(gpa, cur);
        }
    }

    // place scanner 0 at origin
    scanners.items[0].pos = .{ 0, 0, 0 };
    scanners.items[0].rot = 0;

    const n = scanners.items.len;
    var placed_count: usize = 1;

    while (placed_count < n) {
        outer: for (0..n) |j| {
            if (scanners.items[j].pos != null) continue;
            // try to align j against any placed scanner
            for (0..n) |i| {
                if (scanners.items[i].pos == null) continue;
                var i_pts: List(V3) = .empty;
                defer i_pts.deinit(gpa);
                try worldBeacons(i, &i_pts);

                for (0..rotations.count) |r| {
                    // count translation votes
                    var votes = Map(V3, u32).init(gpa);
                    defer votes.deinit();
                    for (i_pts.items) |a| {
                        for (scanners.items[j].beacons.items) |b_raw| {
                            const rm: [9]i64 = rotations.rots[r];
                            const b = applyRot(&rm, b_raw);
                            // t = a - b (scanner j pos)
                            const t = V3{ a[0] - b[0], a[1] - b[1], a[2] - b[2] };
                            const gop = try votes.getOrPut(t);
                            if (!gop.found_existing) gop.value_ptr.* = 0;
                            gop.value_ptr.* += 1;
                        }
                    }
                    var vit = votes.iterator();
                    while (vit.next()) |e| {
                        if (e.value_ptr.* >= 12) {
                            scanners.items[j].pos = e.key_ptr.*;
                            scanners.items[j].rot = r;
                            placed_count += 1;
                            continue :outer;
                        }
                    }
                }
            }
        }
        if (placed_count == 0) break;
    }

    // part 1: unique beacons
    {
        var all = Map(V3, void).init(gpa);
        defer all.deinit();
        for (0..n) |i| {
            var pts: List(V3) = .empty;
            defer pts.deinit(gpa);
            try worldBeacons(i, &pts);
            for (pts.items) |p| {
                try all.put(p, {});
            }
        }
        print("part 1: {d}\n", .{all.count()});
    }

    // part 2: max scanner distance
    {
        var best: i64 = 0;
        for (0..n) |i| {
            for (0..n) |j| {
                const a = scanners.items[i].pos.?;
                const b = scanners.items[j].pos.?;
                const d: i64 = @intCast(@abs(a[0] - b[0]) + @abs(a[1] - b[1]) + @abs(a[2] - b[2]));
                best = @max(best, d);
            }
        }
        print("part 2: {d}\n", .{best});
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
