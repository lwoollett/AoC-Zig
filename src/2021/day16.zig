const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
var alloc: Allocator = undefined;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day16.txt");

var bits: []const u8 = undefined;
var pos: usize = 0;

fn readBits(n: usize) u64 {
    var v: u64 = 0;
    for (0..n) |_| {
        v = (v << 1) | (bits[pos] - '0');
        pos += 1;
    }
    return v;
}

fn hasBits() bool {
    return pos < bits.len;
}

var version_sum: u64 = 0;

fn parsePacket() u64 {
    version_sum += readBits(3);
    const type_id = readBits(3);
    if (type_id == 4) {
        // literal
        var v: u64 = 0;
        while (true) {
            const group = readBits(5);
            v = (v << 4) | (group & 0xf);
            if (group & 0x10 == 0) break;
        }
        return v;
    }
    // operator
    var values: List(u64) = .empty;
    const length_type = readBits(1);
    if (length_type == 0) {
        const sub_len = readBits(15);
        const end = pos + sub_len;
        while (pos < end) {
            values.append(alloc, parsePacket()) catch unreachable;
        }
    } else {
        const sub_count = readBits(11);
        for (0..sub_len_count(sub_count)) |_| {
            values.append(alloc, parsePacket()) catch unreachable;
        }
    }
    _ = &values;
    switch (type_id) {
        0 => {
            var s: u64 = 0;
            for (values.items) |v| s += v;
            return s;
        },
        1 => {
            var p: u64 = 1;
            for (values.items) |v| p *= v;
            return p;
        },
        2 => {
            var m: u64 = std.math.maxInt(u64);
            for (values.items) |v| m = @min(m, v);
            return m;
        },
        3 => {
            var m: u64 = 0;
            for (values.items) |v| m = @max(m, v);
            return m;
        },
        5 => return if (values.items[0] > values.items[1]) 1 else 0,
        6 => return if (values.items[0] < values.items[1]) 1 else 0,
        7 => return if (values.items[0] == values.items[1]) 1 else 0,
        else => return 0,
    }
}

fn sub_len_count(n: u64) usize {
    return @intCast(n);
}

pub fn main() !void {
    alloc = gpa;
    const hex = trim(u8, data, " \n\r\t");
    var bin: List(u8) = .empty;
    defer bin.deinit(gpa);
    for (hex) |c| {
        const v = std.fmt.charToDigit(c, 16) catch unreachable;
        var b: u8 = @intCast(v);
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            try bin.append(gpa, '0' + ((b >> 3) & 1));
            b <<= 1;
        }
    }
    bits = bin.items;
    const result = parsePacket();
    print("part 1: {d}\n", .{version_sum});
    print("part 2: {d}\n", .{result});
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
