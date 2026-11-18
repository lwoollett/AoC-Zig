const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day05.txt");

const Range = struct { lo: i64, hi: i64 };

pub fn main() !void {
    var ranges: List(Range) = .empty;
    defer ranges.deinit(gpa);
    var available: List(i64) = .empty;
    defer available.deinit(gpa);

    var lines = splitSca(u8, data, '\n');
    var in_avail = false;
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) {
            in_avail = true;
            continue;
        }
        if (!in_avail) {
            const dash = indexOf(u8, line, '-').?;
            try ranges.append(gpa, .{
                .lo = try parseInt(i64, line[0..dash], 10),
                .hi = try parseInt(i64, line[dash + 1 ..], 10),
            });
        } else {
            try available.append(gpa, try parseInt(i64, line, 10));
        }
    }

    // part 1: available IDs within any range
    var fresh: u64 = 0;
    for (available.items) |id| {
        for (ranges.items) |r| {
            if (id >= r.lo and id <= r.hi) {
                fresh += 1;
                break;
            }
        }
    }
    print("part 1: {d}\n", .{fresh});

    // part 2: total distinct IDs covered by the union of ranges
    std.mem.sort(Range, ranges.items, {}, struct {
        fn lessThan(_: void, a: Range, b: Range) bool {
            return a.lo < b.lo;
        }
    }.lessThan);
    var covered: i64 = 0;
    var cur_lo: i64 = std.math.minInt(i64);
    var cur_hi: i64 = std.math.minInt(i64);
    for (ranges.items) |r| {
        if (r.lo > cur_hi) {
            if (cur_hi > std.math.minInt(i64)) {
                covered += cur_hi - cur_lo + 1;
            }
            cur_lo = r.lo;
            cur_hi = r.hi;
        } else {
            cur_hi = @max(cur_hi, r.hi);
        }
    }
    if (cur_hi > std.math.minInt(i64)) {
        covered += cur_hi - cur_lo + 1;
    }
    print("part 2: {d}\n", .{covered});
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
