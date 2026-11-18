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

const data = @embedFile("data/day13.txt");

pub fn main() !void {
    // part 1: count block tiles (id 2)
    {
        var vm = try intcode.VM.initSource(gpa, data);
        defer vm.deinit();
        while (!vm.halted) _ = try vm.step();
        var blocks: usize = 0;
        const out = vm.outputs.items;
        var i: usize = 0;
        while (i + 2 < out.len) : (i += 3) {
            if (out[i + 2] == 2) blocks += 1;
        }
        print("part 1: {d}\n", .{blocks});
    }

    // part 2: play with free credits and paddle tracking
    var vm = try intcode.VM.initSource(gpa, data);
    defer vm.deinit();
    try vm.write(0, 2); // insert coin

    var ball_x: i64 = 0;
    var paddle_x: i64 = 0;
    var score: i64 = 0;
    var consumed: usize = 0;

    while (!vm.halted) {
        // run until input needed or halt
        while (!vm.halted) {
            const r = try vm.step();
            if (r == .need_input) break;
        }
        // consume outputs in triples
        const out = vm.outputs.items;
        while (consumed + 2 < out.len + 1 and consumed + 3 <= out.len) : (consumed += 3) {
            const x = out[consumed];
            const y = out[consumed + 1];
            const t = out[consumed + 2];
            if (x == -1 and y == 0) {
                score = t;
            } else if (t == 3) {
                paddle_x = x;
            } else if (t == 4) {
                ball_x = x;
            }
        }
        if (vm.halted) break;
        // joystick follows the ball
        const joy: i64 = if (ball_x > paddle_x) 1 else if (ball_x < paddle_x) -1 else 0;
        try vm.addInput(joy);
    }
    print("part 2: {d}\n", .{score});
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
