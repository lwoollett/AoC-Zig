const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day07.txt");

const Rule = struct { count: u64, inner: []const u8 };

var rules = StrMap(List(Rule)).init(std.heap.page_allocator);
var contains_cache = StrMap(bool).init(std.heap.page_allocator);

/// Can `bag` eventually hold a shiny gold bag?
fn canHold(bag: []const u8) anyerror!bool {
    if (contains_cache.get(bag)) |v| return v;
    var result = false;
    if (rules.get(bag)) |inner| {
        for (inner.items) |r| {
            if (std.mem.eql(u8, r.inner, "shiny gold")) {
                result = true;
                break;
            }
            if (try canHold(r.inner)) {
                result = true;
                break;
            }
        }
    }
    try contains_cache.put(bag, result);
    return result;
}

/// Total bags contained inside `bag` (not counting itself).
fn bagsInside(bag: []const u8) u64 {
    var total: u64 = 0;
    if (rules.get(bag)) |inner| {
        for (inner.items) |r| {
            total += r.count * (1 + bagsInside(r.inner));
        }
    }
    return total;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "light red bags contain 1 bright white bag, 2 muted yellow bags."
        const bags_idx = std.mem.indexOf(u8, line, " bags contain").?;
        const outer = line[0..bags_idx];
        const rest = line[bags_idx + " bags contain".len ..];
        if (std.mem.startsWith(u8, rest, " no other bags")) continue;

        var it = tokenizeAny(u8, rest[0 .. rest.len - 1], ",");
        while (it.next()) |part_raw| {
            const part = trim(u8, part_raw, " ");
            const sp = indexOf(u8, part, ' ').?;
            const count = try parseInt(u64, part[0..sp], 10);
            var inner = part[sp + 1 ..];
            // strip " bag(s)"
            inner = trim(u8, inner, " ");
            if (std.mem.endsWith(u8, inner, " bags")) {
                inner = inner[0 .. inner.len - 5];
            } else if (std.mem.endsWith(u8, inner, " bag")) {
                inner = inner[0 .. inner.len - 4];
            }
            const gop = try rules.getOrPut(outer);
            if (!gop.found_existing) gop.value_ptr.* = .empty;
            try gop.value_ptr.append(std.heap.page_allocator, .{ .count = count, .inner = inner });
        }
    }

    var count: u32 = 0;
    var kit = rules.keyIterator();
    while (kit.next()) |k| {
        if (try canHold(k.*)) count += 1;
    }
    print("part 1: {d}\n", .{count});
    print("part 2: {d}\n", .{bagsInside("shiny gold")});
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
