const std = @import("std");

const util = @import("util");
const gpa = util.gpa;
const intcode = @import("intcode");


const data = @embedFile("data/day09.txt");

pub fn main() !void {
    {
        var vm = try intcode.VM.initSource(gpa, data);
        defer vm.deinit();
        _ = try vm.runWith(1);
        print("part 1: {d}\n", .{vm.lastOutput()});
    }
    {
        var vm = try intcode.VM.initSource(gpa, data);
        defer vm.deinit();
        _ = try vm.runWith(2);
        print("part 2: {d}\n", .{vm.lastOutput()});
    }
}

// Useful stdlib functions

const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
