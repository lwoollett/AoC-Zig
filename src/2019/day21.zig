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

const data = @embedFile("data/day21.txt");

fn runProgram(comptime mode: []const u8) !i64 {
    var vm = try intcode.VM.initSource(gpa, data);
    defer vm.deinit();

    var program: List(u8) = .empty;
    defer program.deinit(gpa);
    if (comptime std.mem.eql(u8, mode, "walk")) {
        try program.appendSlice(gpa, "NOT A J\nNOT B T\nOR T J\nNOT C T\nOR T J\nAND D J\nWALK\n");
    } else {
        // RUN: also require a safe landing beyond D (E or H)
        try program.appendSlice(gpa, "NOT A J\nNOT B T\nOR T J\nNOT C T\nOR T J\nAND D J\nNOT E T\nNOT T T\nOR H T\nAND T J\nRUN\n");
    }
    for (program.items) |c| try vm.addInput(c);

    var txt: List(u8) = .empty;
    defer txt.deinit(gpa);
    while (!vm.halted) _ = try vm.step();
    for (vm.outputs.items) |v| {
        if (v > 127) return v; // hull damage number
        try txt.append(gpa, @intCast(v));
    }
    print("no damage number; output:\n{s}\n", .{txt.items});
    return error.NoDamage;
}

pub fn main() !void {
    print("part 1: {d}\n", .{try runProgram("walk")});
    print("part 2: {d}\n", .{try runProgram("run")});
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
