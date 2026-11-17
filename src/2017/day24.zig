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

const max_ports = 64;

const Comp = struct { a: u32, b: u32, used: bool = false };

var comps: [max_ports]Comp = @splat(.{ .a = 0, .b = 0, .used = false });
var n_comps: usize = 0;
var best_strength: u64 = 0;
var best_longest_strength: u64 = 0;
var best_length: usize = 0;

fn build(port: u32, strength: u64, length: usize) void {
    if (strength > best_strength) best_strength = strength;
    if (length > best_length or (length == best_length and strength > best_longest_strength)) {
        best_length = length;
        best_longest_strength = strength;
    }
    for (comps[0..n_comps]) |*c| {
        if (c.used) continue;
        var next: ?u32 = null;
        if (c.a == port) next = c.b;
        if (c.b == port) next = c.a;
        if (next) |np| {
            c.used = true;
            build(np, strength + c.a + c.b, length + 1);
            c.used = false;
        }
    }
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const slash = std.mem.findScalar(u8, line, '/').?;
        comps[n_comps] = .{
            .a = try parseInt(u32, line[0..slash], 10),
            .b = try parseInt(u32, trim(u8, line[slash + 1 ..], " \r"), 10),
        };
        n_comps += 1;
    }

    build(0, 0, 0);
    print("part 1: {d}\n", .{best_strength});
    print("part 2: {d}\n", .{best_longest_strength});
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
