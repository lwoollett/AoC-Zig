const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day24.txt");

// integer-indexed gate graph
const Gate = struct { in1: u32, in2: u32, op: u8, out: u32 }; // op: 'A','O','X'
var gates: List(Gate) = .empty;
var wire_id = StrMap(u32).init(std.heap.page_allocator);
var wire_names: List([]const u8) = .empty;
var input_wires: List(u32) = .empty; // x/y input wire ids (index 2i = x_i? no—stored explicitly)
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

    // part 2: greedy swap repair — maximize the lowest incorrect z bit
    {
        initTests();
        var swapped: List([]const u8) = .empty;
        defer swapped.deinit(gpa);

        var round: usize = 0;
        while (round < 4) : (round += 1) {
            const cur = circuitScore();
            if (cur.wrong == 0) break;
            // candidate gates: the cone of gates feeding the lowest wrong z bit
            var cone = Map(usize, void).init(gpa);
            defer cone.deinit();
            {
                var target: []const u8 = "";
                var buf: [8]u8 = undefined;
                target = std.fmt.bufPrint(&buf, "z{d:0>2}", .{cur.lowest}) catch "";
                var queue: List([]const u8) = .empty;
                defer queue.deinit(gpa);
                try queue.append(gpa, target);
                var depth: usize = 0;
                while (queue.items.len > 0 and depth < 200) : (depth += 1) {
                    const wname = queue.pop().?;
                    for (gates.items, 0..) |g, gi| {
                        if (std.mem.eql(u8, wire_names.items[g.out], wname)) {
                            if (!cone.contains(gi)) {
                                try cone.put(gi, {});
                                try queue.append(gpa, wire_names.items[g.in1]);
                                try queue.append(gpa, wire_names.items[g.in2]);
                            }
                        }
                    }
                }
            }
            var best_score = circuitScore();
            var best_i: usize = 0;
            var best_j: usize = 0;
            var found = false;
            for (gates.items, 0..) |*gi, i| {
                for (gates.items[i + 1 ..], i + 1..) |*gj, j| {
                    if (!cone.contains(i) and !cone.contains(j)) continue;
                    std.mem.swap(u32, &gi.out, &gj.out);
                    const s = circuitScore();
                    if (s.wrong < 900) {
                        if (!found or s.lowest > best_score.lowest or
                            (s.lowest == best_score.lowest and s.wrong < best_score.wrong))
                        {
                            best_score = s;
                            best_i = i;
                            best_j = j;
                            found = true;
                        }
                    }
                    std.mem.swap(u32, &gi.out, &gj.out);
                }
            }
            if (!found) {
                print("part 2: stuck at round {d}\n", .{round});
                break;
            }
            std.mem.swap(u32, &gates.items[best_i].out, &gates.items[best_j].out);
            try swapped.append(gpa, wire_names.items[gates.items[best_i].out]);
            try swapped.append(gpa, wire_names.items[gates.items[best_j].out]);
        }

        const fin = circuitScore();
        if (fin.wrong != 0) {
            print("part 2: repair incomplete ({d} wrong bits)\n", .{fin.wrong});
        }

        std.mem.sort([]const u8, swapped.items, {}, struct {
            fn lessThan(_: void, a: []const u8, b: []const u8) bool {
                return std.mem.order(u8, a, b) == .lt;
            }
        }.lessThan);
        print("part 2: ", .{});
        for (swapped.items, 0..) |s, i| {
            if (i > 0) print(",", .{});
            print("{s}", .{s});
        }
        print("\n", .{});
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
