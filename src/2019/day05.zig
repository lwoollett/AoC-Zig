const std = @import("std");

const util = @import("util");
const gpa = util.gpa;
const intcode = @import("intcode");

// const zom = @import("zom");

const data = @embedFile("data/day05.txt");

pub fn main() !void {
    // p1: input 1 — all outputs should be 0 except the diagnostic (last)
    {
        var vm = try intcode.VM.initSource(gpa, data);
        defer vm.deinit();
        _ = try vm.runWith(1);
        print("part 1 outputs: {any}\n", .{vm.outputs.items});
        print("part 1: {d}\n", .{vm.lastOutput()});
    }
    // p2: input 5
    {
        var vm = try intcode.VM.initSource(gpa, data);
        defer vm.deinit();
        _ = try vm.runWith(5);
        print("part 2: {d}\n", .{vm.lastOutput()});
    }
}

// Useful stdlib functions

const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
