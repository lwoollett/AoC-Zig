const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day12.txt");

const Moon = struct { p: [3]i64, v: [3]i64 = .{ 0, 0, 0 } };

fn parseMoons() !List(Moon) {
    var moons: List(Moon) = .empty;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // <x=-1, y=0, z=2>
        var nums: [3]i64 = undefined;
        var i: usize = 0;
        var it = tokenizeAny(u8, line, "<xyz=, >");
        while (it.next()) |tok| {
            nums[i] = try parseInt(i64, tok, 10);
            i += 1;
        }
        try moons.append(gpa, .{ .p = nums });
    }
    return moons;
}

fn energy(moons: []const Moon) i64 {
    var total: i64 = 0;
    for (moons) |m| {
        var pot: i64 = 0;
        var kin: i64 = 0;
        for (0..3) |ax| {
            pot += @as(i64, @intCast(@abs(m.p[ax])));
            kin += @as(i64, @intCast(@abs(m.v[ax])));
        }
        total += pot * kin;
    }
    return total;
}

pub fn main() !void {
    // part 1: 1000 steps
    {
        var moons = try parseMoons();
        defer moons.deinit(gpa);
        var step: usize = 0;
        while (step < 1000) : (step += 1) {
            for (0..moons.items.len) |i| {
                for (0..moons.items.len) |j| {
                    if (i == j) continue;
                    for (0..3) |ax| {
                        const a = moons.items[i].p[ax];
                        const b = moons.items[j].p[ax];
                        moons.items[i].v[ax] += @as(i64, if (a < b) 1 else if (a > b) @as(i64, -1) else 0);
                    }
                }
            }
            for (moons.items) |*m| {
                for (0..3) |ax| m.p[ax] += m.v[ax];
            }
        }
        print("part 1: {d}\n", .{energy(moons.items)});
    }

    // part 2: per-axis period, then LCM
    var lcm: u128 = 1;
    for (0..3) |ax| {
        var moons = try parseMoons();
        defer moons.deinit(gpa);

        const AxisState = [8]i64; // 4 pos + 4 vel
        var seen = Map(u64, u64).init(gpa);
        defer seen.deinit();

        var step: u64 = 0;
        while (true) {
            // hash axis state
            var st: AxisState = undefined;
            for (0..4) |i| {
                st[i] = moons.items[i].p[ax];
                st[4 + i] = moons.items[i].v[ax];
            }
            var h = std.hash.Wyhash.init(0);
            h.update(std.mem.asBytes(&st));
            const key = h.final();
            if (seen.get(key)) |first| {
                const period: u128 = step - first;
                // lcm
                const g = std.math.gcd(lcm, period);
                lcm = lcm / g * period;
                break;
            }
            try seen.put(key, step);
            // advance all axes (must simulate fully: velocity depends only on
            // same-axis positions, so simulating this axis alone is exact)
            for (0..4) |i| {
                for (0..4) |j| {
                    if (i == j) continue;
                    const a = moons.items[i].p[ax];
                    const b = moons.items[j].p[ax];
                    moons.items[i].v[ax] += @as(i64, if (a < b) 1 else if (a > b) @as(i64, -1) else 0);
                }
            }
            for (moons.items) |*m| m.p[ax] += m.v[ax];
            step += 1;
        }
    }
    print("part 2: {d}\n", .{lcm});
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
