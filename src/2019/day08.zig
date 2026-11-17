const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day08.txt");

const w = 25;
const h = 6;

pub fn main() !void {
    const digits = trim(u8, data, " \n\r\t");
    const layer_size = w * h;
    const n_layers = digits.len / layer_size;

    // part 1: fewest zeros
    var best_zeros: usize = std.math.maxInt(usize);
    var best_ones: usize = 0;
    var best_twos: usize = 0;
    for (0..n_layers) |l| {
        const layer = digits[l * layer_size .. (l + 1) * layer_size];
        var zeros: usize = 0;
        var ones: usize = 0;
        var twos: usize = 0;
        for (layer) |c| {
            switch (c) {
                '0' => zeros += 1,
                '1' => ones += 1,
                '2' => twos += 1,
                else => {},
            }
        }
        if (zeros < best_zeros) {
            best_zeros = zeros;
            best_ones = ones;
            best_twos = twos;
        }
    }
    print("part 1: {d}\n", .{best_ones * best_twos});

    // part 2: composite the image (0 black, 1 white, 2 transparent)
    var image: [h][w]u8 = @splat(@splat('2'));
    for (0..n_layers) |l| {
        const layer = digits[l * layer_size .. (l + 1) * layer_size];
        for (0..h) |y| {
            for (0..w) |x| {
                if (image[y][x] == '2') {
                    image[y][x] = layer[y * w + x];
                }
            }
        }
    }
    print("part 2 (read the letters):\n", .{});
    for (image) |row| {
        for (row) |c| {
            print("{s}", .{if (c == '1') "#" else " "});
        }
        print("\n", .{});
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
