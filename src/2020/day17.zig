const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day17.txt");

const P3 = [3]i32;
const P4 = [4]i32;

fn cycle3(active: *Map(P3, void)) !void {
    var counts = Map(P3, u8).init(gpa);
    defer counts.deinit();
    var it = active.keyIterator();
    while (it.next()) |p| {
        var dx: i32 = -1;
        while (dx <= 1) : (dx += 1) {
            var dy: i32 = -1;
            while (dy <= 1) : (dy += 1) {
                var dz: i32 = -1;
                while (dz <= 1) : (dz += 1) {
                    if (dx == 0 and dy == 0 and dz == 0) continue;
                    const q = P3{ p[0] + dx, p[1] + dy, p[2] + dz };
                    const gop = try counts.getOrPut(q);
                    if (!gop.found_existing) gop.value_ptr.* = 0;
                    gop.value_ptr.* += 1;
                }
            }
        }
    }
    var next = Map(P3, void).init(gpa);
    var cit = counts.iterator();
    while (cit.next()) |e| {
        const p = e.key_ptr.*;
        const was_active = active.contains(p);
        if (was_active and (e.value_ptr.* == 2 or e.value_ptr.* == 3)) {
            try next.put(p, {});
        } else if (!was_active and e.value_ptr.* == 3) {
            try next.put(p, {});
        }
    }
    active.deinit();
    active.* = next;
}

fn cycle4(active: *Map(P4, void)) !void {
    var counts = Map(P4, u8).init(gpa);
    defer counts.deinit();
    var it = active.keyIterator();
    while (it.next()) |p| {
        var dx: i32 = -1;
        while (dx <= 1) : (dx += 1) {
            var dy: i32 = -1;
            while (dy <= 1) : (dy += 1) {
                var dz: i32 = -1;
                while (dz <= 1) : (dz += 1) {
                    var dw: i32 = -1;
                    while (dw <= 1) : (dw += 1) {
                        if (dx == 0 and dy == 0 and dz == 0 and dw == 0) continue;
                        const q = P4{ p[0] + dx, p[1] + dy, p[2] + dz, p[3] + dw };
                        const gop = try counts.getOrPut(q);
                        if (!gop.found_existing) gop.value_ptr.* = 0;
                        gop.value_ptr.* += 1;
                    }
                }
            }
        }
    }
    var next = Map(P4, void).init(gpa);
    var cit = counts.iterator();
    while (cit.next()) |e| {
        const p = e.key_ptr.*;
        const was_active = active.contains(p);
        if (was_active and (e.value_ptr.* == 2 or e.value_ptr.* == 3)) {
            try next.put(p, {});
        } else if (!was_active and e.value_ptr.* == 3) {
            try next.put(p, {});
        }
    }
    active.deinit();
    active.* = next;
}

pub fn main() !void {
    var lines: List([]const u8) = .empty;
    defer lines.deinit(gpa);
    var it = tokenizeAny(u8, data, "\n");
    while (it.next()) |line| {
        try lines.append(gpa, line);
    }

    // part 1: 3D
    {
        var active = Map(P3, void).init(gpa);
        defer active.deinit();
        for (lines.items, 0..) |line, y| {
            for (line, 0..) |c, x| {
                if (c == '#') {
                    try active.put(.{ @intCast(x), @intCast(y), 0 }, {});
                }
            }
        }
        var i: u32 = 0;
        while (i < 6) : (i += 1) {
            try cycle3(&active);
        }
        print("part 1: {d}\n", .{active.count()});
    }

    // part 2: 4D
    {
        var active = Map(P4, void).init(gpa);
        defer active.deinit();
        for (lines.items, 0..) |line, y| {
            for (line, 0..) |c, x| {
                if (c == '#') {
                    try active.put(.{ @intCast(x), @intCast(y), 0, 0 }, {});
                }
            }
        }
        var i: u32 = 0;
        while (i < 6) : (i += 1) {
            try cycle4(&active);
        }
        print("part 2: {d}\n", .{active.count()});
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
