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

const Range = struct { dst: u64, src: u64, len: u64 };
const Mapping = struct { name: []const u8, ranges: List(Range) = .empty };

fn mapValue(m: *const Mapping, v: u64) u64 {
    for (m.ranges.items) |r| {
        if (v >= r.src and v < r.src + r.len) {
            return r.dst + (v - r.src);
        }
    }
    return v;
}

fn mapRanges(m: *const Mapping, in: []const [2]u64, out: *List([2]u64)) !void {
    // in: list of [start, len) intervals; remap piecewise
    var work: List([2]u64) = .empty;
    defer work.deinit(gpa);
    try work.appendSlice(gpa, in);

    for (m.ranges.items) |r| {
        var next: List([2]u64) = .empty;
        for (work.items) |iv| {
            const s = iv[0];
            const e = iv[0] + iv[1];
            const rs = r.src;
            const re = r.src + r.len;
            // overlap
            const os = @max(s, rs);
            const oe = @min(e, re);
            if (os < oe) {
                // mapped piece
                try out.append(gpa, .{ r.dst + (os - rs), oe - os });
                // unmapped left/right
                if (s < os) try next.append(gpa, .{ s, os - s });
                if (oe < e) try next.append(gpa, .{ oe, e - oe });
            } else {
                try next.append(gpa, iv);
            }
        }
        work.deinit(gpa);
        work = next; // ownership moves; next has no defer
    }
    // leftover unmapped pieces pass through
    for (work.items) |iv| {
        try out.append(gpa, iv);
    }
}

pub fn main() !void {
    var seeds: List(u64) = .empty;
    defer seeds.deinit(gpa);
    var mappings: List(Mapping) = .empty;
    defer mappings.deinit(gpa);

    var lines = splitSca(u8, data, '\n');
    {
        const first = lines.next().?;
        var it = tokenizeAny(u8, first[7..], " ");
        while (it.next()) |tok| {
            try seeds.append(gpa, try parseInt(u64, tok, 10));
        }
    }
    var cur: Mapping = undefined;
    var have_cur = false;
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) {
            if (have_cur) {
                try mappings.append(gpa, cur);
                have_cur = false;
            }
            continue;
        }
        if (std.mem.indexOfScalar(u8, line, ':') != null and
            std.mem.indexOfScalar(u8, line, ' ') != null and
            line[line.len - 1] == ':' and !std.ascii.isDigit(line[0]))
        {
            cur = Mapping{ .name = line[0 .. line.len - 5] };
            have_cur = true;
            continue;
        }
        var it = tokenizeSca(u8, line, ' ');
        const dst = try parseInt(u64, it.next().?, 10);
        const src = try parseInt(u64, it.next().?, 10);
        const len = try parseInt(u64, it.next().?, 10);
        try cur.ranges.append(gpa, .{ .dst = dst, .src = src, .len = len });
    }
    if (have_cur) {
        try mappings.append(gpa, cur);
    }

    // part 1: per-seed mapping
    var best: u64 = std.math.maxInt(u64);
    for (seeds.items) |s_in| {
        var v = s_in;
        for (mappings.items) |*m| {
            v = mapValue(m, v);
        }
        best = @min(best, v);
    }
    print("part 1: {d}\n", .{best});

    // part 2: interval mapping
    var intervals: List([2]u64) = .empty;
    defer intervals.deinit(gpa);
    {
        var i: usize = 0;
        while (i + 1 < seeds.items.len) : (i += 2) {
            try intervals.append(gpa, .{ seeds.items[i], seeds.items[i + 1] });
        }
    }
    for (mappings.items) |*m| {
        var out: List([2]u64) = .empty;
        defer out.deinit(gpa);
        try mapRanges(m, intervals.items, &out);
        intervals.clearRetainingCapacity();
        try intervals.appendSlice(gpa, out.items);
    }
    best = std.math.maxInt(u64);
    for (intervals.items) |iv| {
        best = @min(best, iv[0]);
    }
    print("part 2: {d}\n", .{best});
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
