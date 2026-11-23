const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;
const intcode = @import("intcode");


const data = @embedFile("data/day19.txt");

var beam_cache = Map([2]i64, bool).init(std.heap.page_allocator);
var probe_vm: ?intcode.VM = null;

fn beam(x: i64, y: i64) !bool {
    const key = [2]i64{ x, y };
    if (beam_cache.get(key)) |v| return v;
    // reuse a parsed program instead of re-tokenizing the source each probe
    if (probe_vm == null) {
        probe_vm = try intcode.VM.initSource(gpa, data);
    }
    var vm = try probe_vm.?.initClone(gpa);
    defer vm.deinit();
    try vm.addInput(x);
    try vm.addInput(y);
    while (!vm.halted) _ = try vm.step();
    const v = vm.lastOutput() == 1;
    try beam_cache.put(key, v);
    return v;
}

pub fn main() !void {
    // part 1: 50x50 affected points
    var count: u32 = 0;
    for (0..50) |y| {
        for (0..50) |x| {
            if (try beam(@intCast(x), @intCast(y))) count += 1;
        }
    }
    print("part 1: {d}\n", .{count});

    // part 2: closest 100x100 square entirely in the beam.
    // The beam tilts right (~1.57 x/y), so the square hangs from the BOTTOM
    // row: anchor x on row y's left edge, square top-left is (x, y - 99).
    const size: i64 = 100;
    var x: i64 = 0;
    var y: i64 = 100;
    while (true) : (y += 1) {
        // re-sync x to the beam's left edge on this row
        while (x > 0 and try beam(x - 1, y)) x -= 1;
        while (!try beam(x, y)) x += 1;
        // square bottom row is y; check bottom-right, top-left, top-right
        if (try beam(x + size - 1, y) and try beam(x, y - size + 1) and try beam(x + size - 1, y - size + 1)) {
            print("part 2: {d}\n", .{x * 10000 + (y - size + 1)});
            return;
        }
    }
}

// Useful stdlib functions

const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
