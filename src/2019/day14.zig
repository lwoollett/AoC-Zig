const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day14.txt");

const Ingredient = struct { qty: u64, name: []const u8 };
const Reaction = struct { out_qty: u64, inputs: []Ingredient };

var reactions: StrMap(Reaction) = undefined;
var arena: std.heap.ArenaAllocator = undefined;

fn parse() !void {
    arena = std.heap.ArenaAllocator.init(gpa);
    const a = arena.allocator();
    reactions = StrMap(Reaction).init(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const arrow = std.mem.findScalar(u8, line, '>').?;
        const lhs = line[0 .. arrow - 1];
        const rhs = trim(u8, line[arrow + 2 ..], " ");

        var inputs: List(Ingredient) = .empty;
        var it = tokenizeSca(u8, lhs, ',');
        while (it.next()) |tok| {
            const t = trim(u8, tok, " ");
            const sp = indexOf(u8, t, ' ').?;
            try inputs.append(a, .{
                .qty = try parseInt(u64, t[0..sp], 10),
                .name = t[sp + 1 ..],
            });
        }

        const sp = indexOf(u8, rhs, ' ').?;
        const name = try a.dupe(u8, rhs[sp + 1 ..]);
        const out_qty = try parseInt(u64, rhs[0..sp], 10);
        try reactions.put(name, .{ .out_qty = out_qty, .inputs = try inputs.toOwnedSlice(a) });
    }
}

/// Ore needed to produce `fuel_amt` FUEL (with leftover surplus discarded between calls).
fn oreForFuel(alloc: std.mem.Allocator, fuel_amt: u64) !u64 {
    var need = StrMap(u64).init(alloc);
    defer need.deinit();
    try need.put("FUEL", fuel_amt);
    var ore: u64 = 0;
    var surplus = StrMap(u64).init(alloc);
    defer surplus.deinit();

    var stack: List([]const u8) = .empty;
    defer stack.deinit(alloc);
    try stack.append(alloc, "FUEL");

    while (stack.pop()) |chem| {
        if (std.mem.eql(u8, chem, "ORE")) {
            ore += need.get("ORE").?;
            if (need.getPtr("ORE")) |p| p.* = 0;
            continue;
        }
        const need_amt = need.get(chem) orelse 0;
        if (need_amt == 0) continue;
        // apply surplus
        var remaining = need_amt;
        if (surplus.get(chem)) |s| {
            const used = @min(s, remaining);
            remaining -= used;
            const sp = surplus.getPtr(chem).?;
            sp.* -= used;
        }
        if (remaining == 0) {
            if (need.getPtr(chem)) |p| p.* = 0;
            continue;
        }
        const rx = reactions.get(chem).?;
        const batches = (remaining + rx.out_qty - 1) / rx.out_qty;
        const produced = batches * rx.out_qty;
        // store leftover
        if (produced > remaining) {
            const gop = try surplus.getOrPut(chem);
            if (!gop.found_existing) gop.value_ptr.* = 0;
            gop.value_ptr.* += produced - remaining;
        }
        if (need.getPtr(chem)) |p| p.* = 0;
        for (rx.inputs) |ing| {
            const gop = try need.getOrPut(ing.name);
            if (!gop.found_existing) gop.value_ptr.* = 0;
            gop.value_ptr.* += ing.qty * batches;
            // push input if not already queued (it will be re-read via need map)
            if (std.mem.eql(u8, ing.name, "ORE")) {
                ore += need.get("ORE").?;
                if (need.getPtr("ORE")) |p| p.* = 0;
            } else {
                try stack.append(alloc, ing.name);
            }
        }
    }
    return ore;
}

pub fn main() !void {
    try parse();
    defer arena.deinit();

    const ore1 = try oreForFuel(gpa, 1);
    print("part 1: {d}\n", .{ore1});

    // part 2: binary search max fuel for 1e12 ore
    const total_ore: u64 = 1_000_000_000_000;
    var lo: u64 = 1;
    var hi: u64 = total_ore / ore1 * 2; // generous upper bound
    while (lo < hi) {
        const mid = lo + (hi - lo + 1) / 2;
        if (try oreForFuel(gpa, mid) <= total_ore) {
            lo = mid;
        } else {
            hi = mid - 1;
        }
    }
    print("part 2: {d}\n", .{lo});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSca = std.mem.tokenizeScalar;
const indexOf = std.mem.findScalar;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
