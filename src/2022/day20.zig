const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day20.txt");

const Item = struct { value: i64, pos: usize };

pub fn main() !void {
    // part 1
    {
        var nums: List(i64) = .empty;
        defer nums.deinit(gpa);
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            try nums.append(gpa, try parseInt(i64, line, 10));
        }
        const n = nums.items.len;
        // order[i] = which original index is at position i
        var order: List(usize) = .empty;
        defer order.deinit(gpa);
        for (0..n) |i| {
            try order.append(gpa, i);
        }

        for (0..n) |mix_i| {
            // find current position of mix_i
            var at: usize = 0;
            for (order.items, 0..) |v, p| {
                if (v == mix_i) {
                    at = p;
                    break;
                }
            }
            const v = nums.items[mix_i];
            const shift = @mod(v, @as(i64, @intCast(n - 1)));
            var to = at;
            var s: i64 = 0;
            while (s < shift) : (s += 1) {
                const nxt = (to + 1) % n;
                const tmp = order.items[to];
                order.items[to] = order.items[nxt];
                order.items[nxt] = tmp;
                to = nxt;
            }
            if (shift < 0) {
                var s2: i64 = 0;
                while (s2 > shift) : (s2 -= 1) {
                    const prv = if (to == 0) n - 1 else to - 1;
                    const tmp = order.items[to];
                    order.items[to] = order.items[prv];
                    order.items[prv] = tmp;
                    to = prv;
                }
            }
        }

        // locate 0
        var zero_pos: usize = 0;
        for (order.items, 0..) |v, p| {
            if (nums.items[v] == 0) {
                zero_pos = p;
                break;
            }
        }
        var total: i64 = 0;
        for ([3]usize{ 1000, 2000, 3000 }) |off| {
            const p = (zero_pos + off) % n;
            total += nums.items[order.items[p]];
        }
        print("part 1: {d}\n", .{total});
    }

    // part 2: decryption key, 10 rounds
    {
        var nums: List(i64) = .empty;
        defer nums.deinit(gpa);
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            try nums.append(gpa, (try parseInt(i64, line, 10)) * 811589153);
        }
        const n = nums.items.len;
        var order: List(usize) = .empty;
        defer order.deinit(gpa);
        for (0..n) |i| {
            try order.append(gpa, i);
        }

        for (0..10) |_| {
            for (0..n) |mix_i| {
                var at: usize = 0;
                for (order.items, 0..) |v, p| {
                    if (v == mix_i) {
                        at = p;
                        break;
                    }
                }
                const v = nums.items[mix_i];
                var shift = @mod(v, @as(i64, @intCast(n - 1)));
                shift = @mod(shift, @as(i64, @intCast(n - 1)));
                var to = at;
                // move by walking (possibly large shifts — reduce first)
                while (shift != 0) {
                    const dir: i64 = if (shift > 0) 1 else -1;
                    const amount = if (@abs(shift) > n) @as(i64, @intCast(n)) else @as(i64, @intCast(@abs(shift)));
                    var k: i64 = 0;
                    while (k < amount) : (k += 1) {
                        const nxt: usize = if (dir > 0)
                            (to + 1) % n
                        else if (to == 0) n - 1 else to - 1;
                        const tmp = order.items[to];
                        order.items[to] = order.items[nxt];
                        order.items[nxt] = tmp;
                        to = nxt;
                    }
                    shift -= dir * amount;
                }
            }
        }

        var zero_pos: usize = 0;
        for (order.items, 0..) |v, p| {
            if (nums.items[v] == 0) {
                zero_pos = p;
                break;
            }
        }
        var total: i64 = 0;
        for ([3]usize{ 1000, 2000, 3000 }) |off| {
            const p = (zero_pos + off) % n;
            total += nums.items[order.items[p]];
        }
        print("part 2: {d}\n", .{total});
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
// Only unmodified days will be modified.
