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

/// -1 = right order, 1 = wrong, 0 = continue (equal)
fn compare(a: []const u8, b: []const u8) i32 {
    // both numbers?
    const a_num = a[0] != '[';
    const b_num = b[0] != '[';
    if (a_num and b_num) {
        const x = parseInt(i64, a, 10) catch 0;
        const y = parseInt(i64, b, 10) catch 0;
        if (x < y) return -1;
        if (x > y) return 1;
        return 0;
    }
    if (a_num and !b_num) {
        // promote a to a single-element list
        return compareSlices(&.{a}, splitListItems(b));
    }
    if (!a_num and b_num) {
        return compareSlices(splitListItems(a), &.{b});
    }
    return compareSlices(splitListItems(a), splitListItems(b));
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

/// parse the comma-separated elements of a list literal (without brackets)
fn splitListItems(s_in: []const u8) []const []const u8 {
    const a = arena.allocator();
    var items: std.ArrayListUnmanaged([]const u8) = .empty;
    var s = s_in;
    if (s.len >= 2 and s[0] == '[') s = s[1 .. s.len - 1]; // strip brackets
    var depth: i32 = 0;
    var start: usize = 0;
    var i: usize = 0;
    while (i <= s.len) : (i += 1) {
        if (i == s.len or (s[i] == ',' and depth == 0)) {
            if (i > start) {
                items.append(a, s[start..i]) catch unreachable;
            }
            start = i + 1;
            continue;
        }
        if (s[i] == '[') depth += 1;
        if (s[i] == ']') depth -= 1;
    }
    return items.items;
}

fn compareSlices(a: []const []const u8, b: []const []const u8) i32 {
    var i: usize = 0;
    while (i < a.len and i < b.len) : (i += 1) {
        const c = compare(a[i], b[i]);
        if (c != 0) return c;
    }
    if (a.len < b.len) return -1;
    if (a.len > b.len) return 1;
    return 0;
}

fn lessThan(_: void, a: []const u8, b: []const u8) bool {
    return compare(a, b) < 0;
}

pub fn main() !void {
    // part 1
    var total: u32 = 0;
    var packets: List([]const u8) = .empty;
    defer packets.deinit(gpa);
    {
        var lines = splitSca(u8, data, '\n');
        while (lines.next()) |line_raw| {
            const line = trim(u8, line_raw, " \r");
            if (line.len == 0) continue;
            try packets.append(gpa, line);
        }
    }
    var i: usize = 0;
    var pair_index: u32 = 0;
    while (i + 1 < packets.items.len) : (i += 2) {
        pair_index += 1;
        if (compare(packets.items[i], packets.items[i + 1]) < 0) {
            total += pair_index;
        }
    }
    print("part 1: {d}\n", .{total});

    // part 2: sort all packets + dividers
    try packets.append(gpa, "[[2]]");
    try packets.append(gpa, "[[6]]");
    std.mem.sort([]const u8, packets.items, {}, lessThan);
    var product: u32 = 1;
    for (packets.items, 0..) |p, idx| {
        if (std.mem.eql(u8, p, "[[2]]") or std.mem.eql(u8, p, "[[6]]")) {
            product *= @intCast(idx + 1);
        }
    }
    print("part 2: {d}\n", .{product});
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
