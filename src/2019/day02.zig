const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;
const intcode = @import("intcode");

// const zom = @import("zom");

const data = @embedFile("data/day02.txt");

fn runWith(alloc: std.mem.Allocator, src: []const u8, noun: i64, verb: i64) !i64 {
    var vm = try intcode.VM.initSource(alloc, src);
    defer vm.deinit();
    try vm.write(1, noun);
    try vm.write(2, verb);
    _ = try vm.run();
    return vm.mem.items[0];
}

pub fn main() !void {
    const p1 = try runWith(gpa, data, 12, 2);
    print("part 1: {d}\n", .{p1});

    var noun: i64 = 0;
    outer: while (noun < 100) : (noun += 1) {
        var verb: i64 = 0;
        while (verb < 100) : (verb += 1) {
            const out = try runWith(gpa, data, noun, verb);
            if (out == 19690720) {
                print("part 2: {d}\n", .{100 * noun + verb});
                break :outer;
            }
        }
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
