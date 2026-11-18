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

const data = @embedFile("data/day23.txt");

const n_nics = 50;

pub fn main() !void {
    var vms: [n_nics]intcode.VM = undefined;
    var queues: [n_nics]List([2]i64) = @splat(.empty);
    defer for (&queues) |*q| q.deinit(gpa);

    for (&vms, 0..) |*vm, i| {
        vm.* = try intcode.VM.initSource(gpa, data);
        try vm.addInput(@intCast(i));
    }
    defer for (&vms) |*vm| vm.deinit();

    var nat: ?[2]i64 = null;
    var last_nat_y: ?i64 = null;
    var delivered = Map(i64, void).init(gpa);
    defer delivered.deinit();

    var p1_answer: ?i64 = null;
    var p2_answer: ?i64 = null;
    var rounds: usize = 0;

    while (p2_answer == null) {
        rounds += 1;
        if (rounds > 100_000) return error.Runaway;

        var any_packet = false;
        for (&vms, 0..) |*vm, i| {
            // feed one packet or -1
            if (queues[i].items.len > 0) {
                const pkt = queues[i].orderedRemove(0);
                try vm.addInput(pkt[0]);
                try vm.addInput(pkt[1]);
                any_packet = true;
            } else {
                try vm.addInput(-1);
            }
            // run until waiting on a fresh input again (bounded burst per
            // round so one chatty VM cannot starve the loop)
            var fed_neg = false;
            var steps: usize = 0;
            while (!vm.halted and steps < 500) {
                steps += 1;
                const r = try vm.step();
                if (r == .need_input) {
                    if (queues[i].items.len > 0) {
                        const pkt = queues[i].orderedRemove(0);
                        try vm.addInput(pkt[0]);
                        try vm.addInput(pkt[1]);
                        any_packet = true;
                        fed_neg = false;
                    } else if (!fed_neg) {
                        try vm.addInput(-1);
                        fed_neg = true;
                    } else {
                        break;
                    }
                }
            }
            // route any complete packets (triples) in new outputs
            const out = vm.outputs.items;
            while (out.len >= 3) {
                const addr = out[0];
                const x = out[1];
                const y = out[2];
                // consume the triple
                std.mem.copyForwards(i64, out[0 .. out.len - 3], out[3..]);
                vm.outputs.shrinkRetainingCapacity(out.len - 3);
                any_packet = true;
                if (addr == 255) {
                    if (p1_answer == null) p1_answer = y;
                    nat = .{ x, y };
                } else if (addr >= 0 and addr < n_nics) {
                    try queues[@intCast(addr)].append(gpa, .{ x, y });
                }
                break; // recheck length next iteration
            }
        }

        // network idle? deliver NAT
        if (!any_packet and nat != null) {
            const y = nat.?[1];
            if (delivered.contains(y)) {
                p2_answer = y;
            } else {
                try delivered.put(y, {});
                try queues[0].append(gpa, nat.?);
                last_nat_y = y;
            }
        }
    }

    print("part 1: {d}\n", .{p1_answer.?});
    print("part 2: {d}\n", .{p2_answer.?});
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
