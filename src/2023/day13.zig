const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day13.txt");

fn diffCount(a: []const u8, b: []const u8) u32 {
    var n: u32 = 0;
    for (a, b) |x, y| {
        if (x != y) n += 1;
    }
    return n;
}

fn findMirrorRows(pattern: []const []const u8, want_diff: u32) ?usize {
    for (1..pattern.len) |r| {
        var total: u32 = 0;
        var i: usize = r;
        var j: usize = r;
        while (i > 0 and j < pattern.len) {
            i -= 1;
            total += diffCount(pattern[i], pattern[j]);
            j += 1;
        }
        if (total == want_diff) return r;
    }
    return null;
}

pub fn main() !void {
    var total1: u64 = 0;
    var total2: u64 = 0;

    var pattern: List([]const u8) = .empty;
    defer pattern.deinit(gpa);

    var lines = splitSca(u8, data, '\n');
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) {
            if (pattern.items.len > 0) {
                total1 += try score(pattern.items, 0);
                total2 += try score(pattern.items, 1);
                pattern.clearRetainingCapacity();
            }
            continue;
        }
        try pattern.append(gpa, line);
    }
    if (pattern.items.len > 0) {
        total1 += try score(pattern.items, 0);
        total2 += try score(pattern.items, 1);
    }
    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{total2});
}

fn score(pattern: []const []const u8, want_diff: u32) !u64 {
    // horizontal mirror
    if (findMirrorRows(pattern, want_diff)) |r| {
        return @as(u64, r) * 100;
    }
    // vertical: transpose and check
    const w = pattern[0].len;
    var col_list: List([]const u8) = .empty;
    defer col_list.deinit(gpa);
    for (0..w) |x| {
        const col = try gpa.alloc(u8, pattern.len);
        for (pattern, 0..) |row, y| {
            col[y] = row[x];
        }
        try col_list.append(gpa, col);
    }
    if (findMirrorRows(col_list.items, want_diff)) |c| {
        return @intCast(c);
    }
    return error.NoMirror;
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
