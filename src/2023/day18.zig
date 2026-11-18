const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day18.txt");

/// shoelace: area + perimeter/2 + 1 (Pick)
fn lagoonArea(steps: anytype) !i128 {
    var x: i64 = 0;
    var y: i64 = 0;
    var area: i128 = 0;
    var perimeter: i128 = 0;
    while (try steps.next()) |s| {
        const nx = x + s.dx * @as(i64, @intCast(s.len));
        const ny = y + s.dy * @as(i64, @intCast(s.len));
        area += @as(i128, x) * ny - @as(i128, y) * nx;
        perimeter += @as(i128, s.len);
        x = nx;
        y = ny;
    }
    if (area < 0) area = -area;
    return @divTrunc(area, 2) + @divTrunc(perimeter, 2) + 1;
}

const Step = struct { dx: i64, dy: i64, len: u64 };

const P1Iter = struct {
    it: std.mem.TokenIterator(u8, .any),

    fn next(self: *P1Iter) !?Step {
        const tok = self.it.next() orelse return null;
        // "R 6 (#70c710)"
        const sp = indexOf(u8, tok, ' ').?;
        const dir = tok[0];
        const sp2 = std.mem.indexOfPos(u8, tok, sp + 1, " ").?;
        const len = try parseInt(u64, tok[sp + 1 .. sp2], 10);
        return switch (dir) {
            'R' => Step{ .dx = 1, .dy = 0, .len = len },
            'L' => Step{ .dx = -1, .dy = 0, .len = len },
            'U' => Step{ .dx = 0, .dy = -1, .len = len },
            else => Step{ .dx = 0, .dy = 1, .len = len },
        };
    }
};

const P2Iter = struct {
    it: std.mem.TokenIterator(u8, .any),

    fn next(self: *P2Iter) !?Step {
        const tok = self.it.next() orelse return null;
        // "(#70c710)" — last hex digit = dir 0=R,1=D,2=L,3=U; first 5 = len
        const open = indexOf(u8, tok, '(').?;
        const hex = tok[open + 2 .. tok.len - 1];
        const len = try parseInt(u64, hex[0..5], 16);
        return switch (hex[5]) {
            '0' => Step{ .dx = 1, .dy = 0, .len = len },
            '2' => Step{ .dx = -1, .dy = 0, .len = len },
            '3' => Step{ .dx = 0, .dy = -1, .len = len },
            else => Step{ .dx = 0, .dy = 1, .len = len },
        };
    }
};

pub fn main() !void {
    var p1 = P1Iter{ .it = tokenizeAny(u8, data, "\n") };
    print("part 1: {d}\n", .{try lagoonArea(&p1)});
    var p2 = P2Iter{ .it = tokenizeAny(u8, data, "\n") };
    print("part 2: {d}\n", .{try lagoonArea(&p2)});
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
