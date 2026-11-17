const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day23.txt");

const Bot = struct { x: i64, y: i64, z: i64, r: i64 };

fn dist(a: *const Bot, x: i64, y: i64, z: i64) i64 {
    return @as(i64, @intCast(@abs(a.x - x) + @abs(a.y - y) + @abs(a.z - z)));
}

pub fn main() !void {
    var bots: List(Bot) = .empty;
    defer bots.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // pos=<0,0,0>, r=4
        var it = tokenizeAny(u8, line, "pos=<,>r= ");
        const x = try parseInt(i64, it.next().?, 10);
        const y = try parseInt(i64, it.next().?, 10);
        const z = try parseInt(i64, it.next().?, 10);
        const r = try parseInt(i64, it.next().?, 10);
        try bots.append(gpa, .{ .x = x, .y = y, .z = z, .r = r });
    }

    // part 1: bots in range of the strongest
    var strongest: usize = 0;
    for (bots.items, 0..) |b, i| {
        if (b.r > bots.items[strongest].r) strongest = i;
    }
    var in_range: u32 = 0;
    for (bots.items) |b| {
        if (dist(&b, bots.items[strongest].x, bots.items[strongest].y, bots.items[strongest].z) <=
            bots.items[strongest].r)
        {
            in_range += 1;
        }
    }
    print("part 1: {d}\n", .{in_range});

    // part 2: corner enumeration — the optimum lies at a critical coordinate
    // in each axis; candidates are bot centers and center ± r offsets.
    var best_count: u32 = 0;
    var best_dist: i64 = std.math.maxInt(i64);

    for (bots.items) |b| {
        const offs = [_]i64{ -b.r, 0, b.r };
        for (offs) |ox| {
            for (offs) |oy| {
                for (offs) |oz| {
                    const px = b.x + ox;
                    const py = b.y + oy;
                    const pz = b.z + oz;
                    var count: u32 = 0;
                    for (bots.items) |o| {
                        if (dist(&o, px, py, pz) <= o.r) count += 1;
                    }
                    const d: i64 = @intCast(@abs(px) + @abs(py) + @abs(pz));
                    if (count > best_count or (count == best_count and d < best_dist)) {
                        best_count = count;
                        best_dist = d;
                    }
                }
            }
        }
    }
    print("part 2: {d}\n", .{best_dist});
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
