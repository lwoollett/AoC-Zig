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

fn inMemoryLen(s: []const u8) usize {
    // s includes the surrounding double quotes.
    var n: usize = 0;
    var i: usize = 1;
    while (i < s.len - 1) {
        if (s[i] == '\\') {
            if (s[i + 1] == 'x') {
                i += 4;
            } else {
                i += 2;
            }
        } else {
            i += 1;
        }
        n += 1;
    }
    return n;
}

fn encodedLen(s: []const u8) usize {
    // 2 for the new surrounding quotes, plus escaping of \ and ".
    var n: usize = 2;
    for (s) |c| {
        if (c == '\\' or c == '"') {
            n += 2;
        } else {
            n += 1;
        }
    }
    return n;
}

pub fn main() !void {
    var code_total: usize = 0;
    var mem_total: usize = 0;
    var enc_total: usize = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        code_total += line.len;
        mem_total += inMemoryLen(line);
        enc_total += encodedLen(line);
    }

    print("part 1: {d}\n", .{code_total - mem_total});
    print("part 2: {d}\n", .{enc_total - code_total});
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
