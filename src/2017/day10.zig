const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day10.txt");

fn knotHash(input: []const u8) [16]u8 {
    var lengths: [256]u8 = undefined;
    var n: usize = 0;
    for (input) |c| {
        lengths[n] = c;
        n += 1;
    }
    for ([_]u8{ 17, 31, 73, 47, 23 }) |c| {
        lengths[n] = c;
        n += 1;
    }

    var list: [256]u8 = undefined;
    for (&list, 0..) |*v, i| v.* = @intCast(i);

    var pos: usize = 0;
    var skip: usize = 0;
    var round: usize = 0;
    while (round < 64) : (round += 1) {
        for (lengths[0..n]) |len| {
            // reverse len elements starting at pos
            var a = pos;
            var b = (pos + @as(usize, len) - 1) % 256;
            var swaps = @as(usize, len) / 2;
            while (swaps > 0) : (swaps -= 1) {
                std.mem.swap(u8, &list[a], &list[b]);
                a = (a + 1) % 256;
                b = (b + 256 - 1) % 256;
            }
            pos = (pos + len + skip) % 256;
            skip += 1;
        }
    }

    var dense: [16]u8 = undefined;
    for (0..16) |block| {
        var x: u8 = 0;
        for (0..16) |k| {
            x ^= list[block * 16 + k];
        }
        dense[block] = x;
    }
    return dense;
}

pub fn main() !void {
    const input = trim(u8, data, " \n\r\t");

    // Part 1: single round with the comma-separated lengths.
    {
        var lengths: [32]u8 = undefined;
        var n: usize = 0;
        var it = tokenizeAny(u8, input, ",");
        while (it.next()) |tok| {
            lengths[n] = try parseInt(u8, tok, 10);
            n += 1;
        }
        var list: [256]u8 = undefined;
        for (&list, 0..) |*v, i| v.* = @intCast(i);
        var pos: usize = 0;
        var skip: usize = 0;
        for (lengths[0..n]) |len| {
            var a = pos;
            var b = (pos + @as(usize, len) - 1) % 256;
            var swaps = @as(usize, len) / 2;
            while (swaps > 0) : (swaps -= 1) {
                std.mem.swap(u8, &list[a], &list[b]);
                a = (a + 1) % 256;
                b = (b + 256 - 1) % 256;
            }
            pos = (pos + len + skip) % 256;
            skip += 1;
        }
        print("part 1: {d}\n", .{@as(u32, list[0]) * list[1]});
    }

    // Part 2: full knot hash of the raw input.
    const dense = knotHash(input);
    var hex: [32]u8 = undefined;
    const digits = "0123456789abcdef";
    for (dense, 0..) |b, i| {
        hex[i * 2] = digits[b >> 4];
        hex[i * 2 + 1] = digits[b & 0x0f];
    }
    print("part 2: {s}\n", .{hex});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
