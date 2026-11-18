const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day24.txt");

const P = struct { q: i32, r: i32 };

const dirs = [_]P{
    .{ .q = 1, .r = 0 }, // e
    .{ .q = -1, .r = 0 }, // w
    .{ .q = 0, .r = 1 }, // se
    .{ .q = -1, .r = 1 }, // sw
    .{ .q = 0, .r = -1 }, // ne
    .{ .q = 1, .r = -1 }, // nw
};

fn parseTile(line: []const u8) P {
    var p = P{ .q = 0, .r = 0 };
    var i: usize = 0;
    while (i < line.len) {
        if (line[i] == 'e') {
            p.q += 1;
            i += 1;
        } else if (line[i] == 'w') {
            p.q -= 1;
            i += 1;
        } else if (line[i] == 's') {
            if (line[i + 1] == 'e') {
                p.r += 1;
            } else {
                p.q -= 1;
                p.r += 1;
            }
            i += 2;
        } else { // n
            if (line[i + 1] == 'e') {
                p.q += 1;
                p.r -= 1;
            } else {
                p.r -= 1;
            }
            i += 2;
        }
    }
    return p;
}

fn neighbors(p: P) [6]P {
    return .{
        .{ .q = p.q + 1, .r = p.r },
        .{ .q = p.q - 1, .r = p.r },
        .{ .q = p.q, .r = p.r + 1 },
        .{ .q = p.q - 1, .r = p.r + 1 },
        .{ .q = p.q, .r = p.r - 1 },
        .{ .q = p.q + 1, .r = p.r - 1 },
    };
}

pub fn main() !void {
    var black = Map(P, void).init(gpa);
    defer black.deinit();

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const p = parseTile(line);
        if (black.contains(p)) {
            _ = black.remove(p);
        } else {
            try black.put(p, {});
        }
    }
    print("part 1: {d}\n", .{black.count()});

    // part 2: 100 days
    var day: u32 = 0;
    while (day < 100) : (day += 1) {
        var counts = Map(P, u8).init(gpa);
        defer counts.deinit();
        var it = black.keyIterator();
        while (it.next()) |p| {
            for (neighbors(p.*)) |nb| {
                const gop = try counts.getOrPut(nb);
                if (!gop.found_existing) gop.value_ptr.* = 0;
                gop.value_ptr.* += 1;
            }
        }
        var next = Map(P, void).init(gpa);
        var cit = counts.iterator();
        while (cit.next()) |e| {
            const was_black = black.contains(e.key_ptr.*);
            const n = e.value_ptr.*;
            if (was_black and (n == 1 or n == 2)) {
                try next.put(e.key_ptr.*, {});
            } else if (!was_black and n == 2) {
                try next.put(e.key_ptr.*, {});
            }
        }
        black.deinit();
        black = next;
    }
    print("part 2: {d}\n", .{black.count()});
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
