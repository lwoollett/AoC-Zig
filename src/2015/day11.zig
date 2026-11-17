const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day11.txt");

fn increment(pw: []u8) void {
    var i = pw.len - 1;
    while (true) {
        if (i == 0 and pw[i] == 'z') @panic("overflow");
        pw[i] += 1;
        if (pw[i] > 'z') {
            pw[i] = 'a';
            i -= 1;
            continue;
        }
        // Skip forbidden characters entirely.
        if (pw[i] == 'i' or pw[i] == 'o' or pw[i] == 'l') pw[i] += 1;
        break;
    }
}

fn hasStraight(pw: []const u8) bool {
    var i: usize = 0;
    while (i + 2 < pw.len) : (i += 1) {
        if (pw[i + 1] == pw[i] + 1 and pw[i + 2] == pw[i] + 2) return true;
    }
    return false;
}

fn hasTwoPairs(pw: []const u8) bool {
    var pairs: usize = 0;
    var i: usize = 0;
    while (i + 1 < pw.len) : (i += 1) {
        if (pw[i] == pw[i + 1]) {
            pairs += 1;
            i += 1; // pairs must not overlap
        }
    }
    return pairs >= 2;
}

fn valid(pw: []const u8) bool {
    return hasStraight(pw) and hasTwoPairs(pw);
}

pub fn main() !void {
    var pw: [16]u8 = undefined;
    const start = trim(u8, data, " \n\r\t");
    @memcpy(pw[0..start.len], start);
    const p = pw[0..start.len];

    increment(p); // Santa's next password must be strictly after the current one
    while (!valid(p)) increment(p);
    print("part 1: {s}\n", .{p});

    increment(p);
    while (!valid(p)) increment(p);
    print("part 2: {s}\n", .{p});
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
