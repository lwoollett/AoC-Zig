const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day22.txt");

/// Affine map: p -> (a*p + b) mod m
const Affine = struct { a: i128, b: i128, m: i128 };

fn mod(x: i128, m: i128) i128 {
    const r = @mod(x, m);
    return r;
}

fn compose(cur: Affine, next: Affine) Affine {
    // f(p) = a*p+b, then g(f(p)) = A*(a*p+b)+B = (A*a)p + (A*b+B)
    return .{
        .a = mod(next.a * cur.a, cur.m),
        .b = mod(next.a * cur.b + next.b, cur.m),
        .m = cur.m,
    };
}

fn powmod(base: i128, exp: i128, m: i128) i128 {
    var result: i128 = 1;
    var b = mod(base, m);
    var e = exp;
    while (e > 0) {
        if (e & 1 == 1) result = mod(result * b, m);
        b = mod(b * b, m);
        e >>= 1;
    }
    return result;
}

fn inverse(x: i128, m: i128) i128 {
    // m is prime: x^(m-2) mod m
    return powmod(x, m - 2, m);
}

pub fn main() !void {
    // part 1: deck of 10007, position of card 2019
    {
        const m: i128 = 10007;
        var aff = Affine{ .a = 1, .b = 0, .m = m };
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "deal into new stack")) {
                // p -> m-1-p  =>  a=-1, b=m-1
                aff = compose(aff, .{ .a = m - 1, .b = m - 1, .m = m });
            } else if (std.mem.startsWith(u8, line, "cut")) {
                const n = try parseInt(i128, line[4..], 10);
                // p -> p - n
                aff = compose(aff, .{ .a = 1, .b = mod(-n, m), .m = m });
            } else if (std.mem.startsWith(u8, line, "deal with increment")) {
                const n = try parseInt(i128, line["deal with increment ".len..], 10);
                // p -> p * n
                aff = compose(aff, .{ .a = n, .b = 0, .m = m });
            }
        }
        // card 2019 starts at position 2019; its final position:
        print("part 1: {d}\n", .{mod(aff.a * 2019 + aff.b, m)});
    }

    // part 2: 119315717514047 cards, 101741582076661 shuffles, card at index 2020
    {
        const m: i128 = 119315717514047;
        const times: i128 = 101741582076661;

        var aff = Affine{ .a = 1, .b = 0, .m = m };
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "deal into new stack")) {
                aff = compose(aff, .{ .a = m - 1, .b = m - 1, .m = m });
            } else if (std.mem.startsWith(u8, line, "cut")) {
                const n = try parseInt(i128, line[4..], 10);
                aff = compose(aff, .{ .a = 1, .b = mod(-n, m), .m = m });
            } else if (std.mem.startsWith(u8, line, "deal with increment")) {
                const n = try parseInt(i128, line["deal with increment ".len..], 10);
                aff = compose(aff, .{ .a = n, .b = 0, .m = m });
            }
        }

        // aff^times: p -> A*p + B where A = a^t, B = b*(a^t - 1)/(a - 1)
        const A = powmod(aff.a, times, m);
        var B: i128 = undefined;
        if (mod(aff.a - 1, m) == 0) {
            // geometric series degenerates: B = b * times
            B = mod(aff.b * mod(times, m), m);
        } else {
            const geo = mod(mod(A - 1, m) * inverse(mod(aff.a - 1, m), m), m);
            B = mod(aff.b * geo, m);
        }
        // card at final position 2020: c with A*c + B = 2020 (mod m)
        const c = mod(mod(2020 - B, m) * inverse(A, m), m);
        print("part 2: {d}\n", .{c});
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
