const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day14.txt");

var mask_x: [36]bool = @splat(false);

pub fn main() !void {
    var mem1 = Map(u64, u64).init(gpa);
    defer mem1.deinit();
    var mem2 = Map(u64, u64).init(gpa);
    defer mem2.deinit();

    var mask_or: u64 = 0;
    var mask_and: u64 = std.math.maxInt(u64);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "mask = ")) {
            const m = line[7..];
            mask_or = 0;
            mask_and = std.math.maxInt(u64);
            for (m, 0..) |c, i| {
                const bit = 35 - i;
                if (c == '1') {
                    mask_or |= @as(u64, 1) << @intCast(bit);
                } else if (c == '0') {
                    mask_and &= ~(@as(u64, 1) << @intCast(bit));
                }
                mask_x[i] = c == 'X';
            }
        } else if (std.mem.startsWith(u8, line, "mem[")) {
            const rb = indexOf(u8, line, ']').?;
            const addr = try parseInt(u64, line[4..rb], 10);
            const eq = indexOf(u8, line, '=').?;
            const value = try parseInt(u64, line[eq + 2 ..], 10);

            // part 1
            try mem1.put(addr, (value | mask_or) & mask_and);

            // part 2: floating addresses
            const base = (addr | mask_or) & ~xMask();
            try writeFloating(&mem2, base, value, &mask_x, 0);
        }
    }

    var sum1: u64 = 0;
    var it = mem1.valueIterator();
    while (it.next()) |v| sum1 += v.*;
    print("part 1: {d}\n", .{sum1});

    var sum2: u64 = 0;
    var it2 = mem2.valueIterator();
    while (it2.next()) |v| sum2 += v.*;
    print("part 2: {d}\n", .{sum2});
}

fn xMask() u64 {
    var m: u64 = 0;
    for (0..36) |i| {
        if (mask_x[i]) m |= @as(u64, 1) << @intCast(35 - i);
    }
    return m;
}

/// Mask with 1s where mask_x bits are set — recompute each mask change.
fn writeFloating(mem: *Map(u64, u64), base: u64, value: u64, xs: *const [36]bool, idx: usize) !void {
    var i = idx;
    while (i < 36 and !xs[i]) i += 1;
    if (i == 36) {
        try mem.put(base, value);
        return;
    }
    const bit = @as(u64, 1) << @intCast(35 - i);
    try writeFloating(mem, base & ~bit, value, xs, i + 1);
    try writeFloating(mem, base | bit, value, xs, i + 1);
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
