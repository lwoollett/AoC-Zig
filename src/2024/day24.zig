const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day24.txt");

// integer-indexed gate graph
const Gate = struct { in1: u32, in2: u32, op: u8, out: u32 }; // op: 'A','O','X'
var gates: List(Gate) = .empty;
var wire_id = StrMap(u32).init(std.heap.page_allocator);
var wire_names: List([]const u8) = .empty;
var xy_values = StrMap(u64).init(std.heap.page_allocator); // initial x/y/const values

fn wireOf(name: []const u8) !u32 {
    const gop = try wire_id.getOrPut(name);
    if (!gop.found_existing) {
        gop.value_ptr.* = @intCast(wire_names.items.len);
        try wire_names.append(gpa, name);
    }
    return gop.value_ptr.*;
}

// evaluation buffers + precomputed ids (no string work in the hot path)
var values: []u64 = &.{};
var init_ids: List(u32) = .empty;
var init_vals: List(u64) = .empty;
var x_ids: [46]u32 = @splat(0);
var y_ids: [46]u32 = @splat(0);
var z_ids: [46]u32 = @splat(0);
var n_bits: usize = 0;

fn prepareEval() !void {
    values = try gpa.alloc(u64, wire_names.items.len);
    var it = xy_values.iterator();
    while (it.next()) |e| {
        try init_ids.append(gpa, wire_id.get(e.key_ptr.*).?);
        try init_vals.append(gpa, e.value_ptr.*);
    }
    var bit: usize = 0;
    while (bit < 46) : (bit += 1) {
        var buf: [8]u8 = undefined;
        const xn = std.fmt.bufPrint(&buf, "x{d:0>2}", .{bit}) catch break;
        var buf2: [8]u8 = undefined;
        const yn = std.fmt.bufPrint(&buf2, "y{d:0>2}", .{bit}) catch break;
        var buf3: [8]u8 = undefined;
        const zn = std.fmt.bufPrint(&buf3, "z{d:0>2}", .{bit}) catch break;
        x_ids[bit] = wire_id.get(xn) orelse std.math.maxInt(u32);
        y_ids[bit] = wire_id.get(yn) orelse std.math.maxInt(u32);
        z_ids[bit] = wire_id.get(zn) orelse std.math.maxInt(u32);
        n_bits = bit + 1;
    }
}

var eval_unstable = false;

fn evalAll(xv: ?u64, yv: ?u64) void {
    @memset(values, 0);
    for (init_ids.items, init_vals.items) |id, v| {
        values[id] = v;
    }
    if (xv != null) {
        var bit: usize = 0;
        while (bit < n_bits) : (bit += 1) {
            if (x_ids[bit] != std.math.maxInt(u32)) values[x_ids[bit]] = (xv.? >> @intCast(bit)) & 1;
            if (y_ids[bit] != std.math.maxInt(u32)) values[y_ids[bit]] = (yv.? >> @intCast(bit)) & 1;
        }
    }
    // bounded fixpoint: a swap can create a combinational cycle
    eval_unstable = false;
    var pass: usize = 0;
    var changed = true;
    while (changed) {
        changed = false;
        pass += 1;
        if (pass > gates.items.len + 2) {
            eval_unstable = true; // cyclic — score as invalid
            return;
        }
        for (gates.items) |g| {
            const a = values[g.in1];
            const b = values[g.in2];
            const v: u64 = switch (g.op) {
                'A' => a & b,
                'O' => a | b,
                else => a ^ b,
            };
            if (values[g.out] != v) {
                values[g.out] = v;
                changed = true;
            }
        }
    }
}

fn zValue() u64 {
    var total: u64 = 0;
    var bit: usize = 0;
    while (bit < n_bits) : (bit += 1) {
        if (z_ids[bit] != std.math.maxInt(u32) and values[z_ids[bit]] == 1) {
            total |= @as(u64, 1) << @intCast(bit);
        }
    }
    return total;
}

/// fixed test vectors
const n_vecs = 4;
var test_x: [n_vecs]u64 = undefined;
var test_y: [n_vecs]u64 = undefined;

fn initTests() void {
    var prng = std.Random.DefaultPrng.init(0xC0FFEE);
    for (0..n_vecs) |i| {
        test_x[i] = prng.random().intRangeAtMost(u64, 0, (1 << 45) - 1);
        test_y[i] = prng.random().intRangeAtMost(u64, 0, (1 << 45) - 1);
    }
}

fn circuitScore() struct { lowest: u8, wrong: usize } {
    var lowest: u8 = 99;
    var wrong_total: usize = 0;
    for (0..n_vecs) |t| {
        evalAll(test_x[t], test_y[t]);
        if (eval_unstable) return .{ .lowest = 99, .wrong = 999 };
        const expected = test_x[t] + test_y[t];
        const z = zValue();
        const diff = z ^ expected;
        if (diff != 0) {
            wrong_total += @popCount(diff);
            lowest = @min(lowest, @as(u8, @intCast(@ctz(diff))));
        }
    }
    return .{ .lowest = lowest, .wrong = wrong_total };
}

pub fn main() !void {
    var lines = splitSca(u8, data, '\n');
    var in_gates = false;
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) {
            in_gates = true;
            continue;
        }
        if (!in_gates) {
            const colon = indexOf(u8, line, ':').?;
            const w = try wireOf(line[0..colon]);
            _ = w;
            try xy_values.put(line[0..colon], try parseInt(u64, line[colon + 2 ..], 10));
        } else {
            var it = tokenizeSca(u8, line, ' ');
            const in1 = try wireOf(try std.heap.page_allocator.dupe(u8, it.next().?));
            const op_raw = it.next().?;
            const in2 = try wireOf(try std.heap.page_allocator.dupe(u8, it.next().?));
            _ = it.next().?; // ->
            const out = try wireOf(try std.heap.page_allocator.dupe(u8, it.next().?));
            try gates.append(gpa, .{ .in1 = in1, .in2 = in2, .op = op_raw[0], .out = out });
        }
    }

    try prepareEval();
    defer gpa.free(values);

    // part 1
    {
        evalAll(null, null);
        print("part 1: {d}\n", .{zValue()});
    }

    // part 2: the circuit is a ripple-carry adder with four swapped output
    // wires. Iteratively repair: find the lowest wrong z bit; the wire that
    // should feed z_i is displaced — swap it with the occupying wire.
    {
        initTests();
        out_index = Map(u32, usize).init(gpa);
        for (gates.items, 0..) |g, i| {
            try out_index.put(g.out, i);
        }
        out_index_ready = true;

        var swapped: List(u32) = .empty;
        defer swapped.deinit(gpa);
        var round: usize = 0;
        while (round < 4) : (round += 1) {
            const low = lowestWrongBit();
            if (std.c.getenv("D24DBG") != null) print("round {d}: lowest wrong = {any}\n", .{ round, low });
            if (low == null) break;
            const i = low.?;
            var buf: [8]u8 = undefined;
            const zname = std.fmt.bufPrint(&buf, "z{d:0>2}", .{i}) catch unreachable;
            const zi = wire_id.get(zname).?;
            const gi = gateByOut(zi);
            const a_i = gateOutBy('X', x_ids[i], y_ids[i]) orelse return error.NoPropagate;
            var partner: u32 = std.math.maxInt(u32);
            var occupant: u32 = std.math.maxInt(u32);
            var xor_case = false;
            _ = &xor_case;
            if (gates.items[gi].op != 'X') {
                // the z gate holds a displaced carry/generate gate; the real
                // z_i XOR (fed by a_i) outputs some other wire
                for (gates.items) |g| {
                    if (g.op == 'X' and g.out != zi and (g.in1 == a_i or g.in2 == a_i)) {
                        partner = g.out;
                        break;
                    }
                }
            } else {
                // z gate is XOR but fed the wrong wire: swap the occupying
                // non-carry input with the displaced a_i
                const g = gates.items[gi];
                const cand = if (g.in1 == a_i) g.in2 else g.in1;
                const src = gateByOut(cand);
                if (src == std.math.maxInt(usize) or gates.items[src].op != 'O') {
                    partner = a_i;
                    occupant = cand;
                    xor_case = true;
                }
            }
            if (partner == std.math.maxInt(u32)) {
                print("part 2: no swap partner for bit {d}\n", .{i});
                return error.NoPartner;
            }
            // which two gates swap outputs?
            //  - non-XOR z gate: the z gate holds a displaced carry gate;
            //    swap it with the displaced z_i XOR gate.
            //  - XOR z gate with a wrong input: swap the occupying wire's
            //    gate with the a_i gate (the occupant takes over a_i's name,
            //    so z_i reads the propagate signal it expects).
            var ga: usize = gi;
            var gb: usize = gateByOut(partner);
            if (gates.items[gi].op == 'X') {
                ga = gateByOut(occupant);
                gb = gateOutIndexByInputs('X', x_ids[i], y_ids[i]) orelse return error.NoPropagateGate;
            }
            if (gb == std.math.maxInt(usize)) {
                print("part 2: partner {s} has no gate\n", .{wire_names.items[partner]});
                return error.NoPartnerGate;
            }
            std.mem.swap(u32, &gates.items[ga].out, &gates.items[gb].out);
            out_index.put(gates.items[ga].out, ga) catch {};
            out_index.put(gates.items[gb].out, gb) catch {};
            try swapped.append(gpa, gates.items[ga].out);
            try swapped.append(gpa, gates.items[gb].out);
        }
        if (lowestWrongBit() != null) {
            print("part 2: repair incomplete\n", .{});
            return;
        }
        var names: List([]const u8) = .empty;
        defer names.deinit(gpa);
        for (swapped.items) |w| {
            try names.append(gpa, wire_names.items[w]);
        }
        std.mem.sort([]const u8, names.items, {}, struct {
            fn lessThan(_: void, a: []const u8, b: []const u8) bool {
                return std.mem.order(u8, a, b) == .lt;
            }
        }.lessThan);
        print("part 2: ", .{});
        for (names.items, 0..) |n, idx| {
            if (idx > 0) print(",", .{});
            print("{s}", .{n});
        }
        print("\n", .{});
    }
}

fn lowestWrongBit() ?usize {
    // lowest wrong z bit across the pseudo-random test vectors (a single
    // fixed input can mask a displaced gate that happens to agree)
    var lowest: usize = std.math.maxInt(usize);
    for (0..n_vecs) |t| {
        evalAll(test_x[t], test_y[t]);
        if (eval_unstable) return 0;
        const expected = test_x[t] +% test_y[t];
        const z = zValue();
        const diff = z ^ expected;
        if (diff != 0) {
            lowest = @min(lowest, @as(usize, @ctz(diff)));
        }
    }
    if (lowest == std.math.maxInt(usize)) return null;
    return lowest;
}

var out_index: Map(u32, usize) = undefined;
var out_index_ready = false;

fn gateByOut(out: u32) usize {
    if (!out_index_ready) {
        out_index = Map(u32, usize).init(gpa);
        for (gates.items, 0..) |g, i| {
            out_index.put(g.out, i) catch {};
        }
        out_index_ready = true;
    }
    return out_index.get(out) orelse std.math.maxInt(usize);
}

fn gateOutIndexByInputs(op: u8, in1: u32, in2: u32) ?usize {
    for (gates.items, 0..) |g, i| {
        if (g.op == op and ((g.in1 == in1 and g.in2 == in2) or (g.in1 == in2 and g.in2 == in1))) {
            return i;
        }
    }
    return null;
}

fn gateOutBy(op: u8, in1: u32, in2: u32) ?u32 {
    const i = gateOutIndexByInputs(op, in1, in2) orelse return null;
    return gates.items[i].out;
}

// Useful stdlib functions
const tokenizeSca = std.mem.tokenizeScalar;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.findScalar;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
