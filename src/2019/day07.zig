const std = @import("std");
const Allocator = std.mem.Allocator;
const util = @import("util");
const gpa = util.gpa;
const intcode = @import("intcode");


const data = @embedFile("data/day07.txt");

fn ampOutput(alloc: std.mem.Allocator, phase: i64, input: i64) !i64 {
    var vm = try intcode.VM.initSource(alloc, data);
    defer vm.deinit();
    try vm.addInput(phase);
    _ = try vm.runWith(input);
    return vm.lastOutput();
}

var best1: i64 = 0;

fn permuteSimple(phases: *[5]i64, used: *[5]bool, depth: usize) !void {
    if (depth == 5) {
        var signal: i64 = 0;
        for (phases) |ph| {
            signal = try ampOutput(gpa, ph, signal);
        }
        best1 = @max(best1, signal);
        return;
    }
    for (0..5) |i| {
        if (used[i]) continue;
        used[i] = true;
        phases[depth] = @intCast(i);
        try permuteSimple(phases, used, depth + 1);
        used[i] = false;
    }
}

var best2: i64 = 0;

fn permuteFeedback(phases: *[5]i64, used: *[5]bool, depth: usize) !void {
    if (depth == 5) {
        // run the feedback loop
        var amps: [5]intcode.VM = undefined;
        for (&amps, 0..) |*vm, i| {
            vm.* = try intcode.VM.initSource(gpa, data);
            try vm.addInput(phases[i]);
        }
        defer for (&amps) |*vm| vm.deinit();

        var signal: i64 = 0;
        var final_e: i64 = 0;
        while (true) {
            var all_halted = true;
            for (&amps) |*vm| {
                if (vm.halted) continue;
                all_halted = false;
                try vm.addInput(signal);
                const out0 = vm.outputCount();
                // run until output or halt
                while (true) {
                    const r = try vm.step();
                    if (r == .output or r == .halt or r == .need_input) break;
                }
                if (vm.outputCount() > out0) {
                    signal = vm.lastOutput();
                }
            }
            if (all_halted) break;
            final_e = signal;
            // if every amp is halted now, stop
            var done = true;
            for (&amps) |*vm| {
                if (!vm.halted) done = false;
            }
            if (done) break;
        }
        best2 = @max(best2, final_e);
        return;
    }
    for (0..5) |i| {
        if (used[i]) continue;
        used[i] = true;
        phases[depth] = @intCast(i + 5);
        try permuteFeedback(phases, used, depth + 1);
        used[i] = false;
    }
}

pub fn main() !void {
    var phases: [5]i64 = undefined;
    var used: [5]bool = @splat(false);
    try permuteSimple(&phases, &used, 0);
    print("part 1: {d}\n", .{best1});

    used = @splat(false);
    try permuteFeedback(&phases, &used, 0);
    print("part 2: {d}\n", .{best2});
}

// Useful stdlib functions

const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
