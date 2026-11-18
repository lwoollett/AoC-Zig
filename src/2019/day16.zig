const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day16.txt");

fn fftPhase(digits: []u8) void {
    const n = digits.len;
    var next = gpa.alloc(u8, n) catch unreachable;
    defer gpa.free(next);
    for (0..n) |i| {
        // pattern for element i: repeats (i+1) times each of 0,1,0,-1, skip first
        var sum: i64 = 0;
        for (0..n) |j| {
            const k = (j + 1) / (i + 1); // which pattern element
            const m = @mod(k, 4);
            const sign: i64 = switch (m) {
                0 => 0,
                1 => 1,
                2 => 0,
                else => -1,
            };
            sum += sign * @as(i64, digits[j] - '0');
        }
        next[i] = @as(u8, @intCast(@mod(@abs(sum), 10))) + '0';
    }
    @memcpy(digits, next);
}

pub fn main() !void {
    const input = trim(u8, data, " \n\r\t");
    const n = input.len;

    // part 1: 100 phases, first 8 digits
    {
        var digits = try gpa.alloc(u8, n);
        defer gpa.free(digits);
        @memcpy(digits, input);
        for (0..100) |_| fftPhase(digits);
        print("part 1: ", .{});
        for (digits[0..8]) |c| print("{c}", .{c});
        print("\n", .{});
    }

    // part 2: offset trick — suffix sums only
    {
        const total_len = n * 10000;
        var offset: usize = 0;
        for (input[0..7]) |c| offset = offset * 10 + (c - '0');
        // sanity: offset must be in the second half for the trick to apply
        if (offset * 2 >= total_len) {
            var tail = try gpa.alloc(u8, total_len - offset);
            defer gpa.free(tail);
            for (0..tail.len) |i| tail[i] = input[@mod(offset + i, n)];
            for (0..100) |_| {
                // value[i] = (sum of tail[i..]) mod 10
                var acc: u8 = 0;
                var i = tail.len;
                while (i > 0) {
                    i -= 1;
                    acc = (acc + (tail[i] - '0')) % 10;
                    tail[i] = acc + '0';
                }
            }
            print("part 2: ", .{});
            for (tail[0..8]) |c| print("{c}", .{c});
            print("\n", .{});
        } else {
            print("part 2: offset {d} not in second half — trick inapplicable\n", .{offset});
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
