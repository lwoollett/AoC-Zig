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

const Gate = struct { in1: []const u8, in2: []const u8, op: u8, out: []const u8 };
var gates: List(Gate) = .empty;
var inputs = StrMap(u64).init(std.heap.page_allocator);

fn evalAll(vals: *StrMap(u64)) !void {
    // topological: iterate until stable
    var pending: List(Gate) = .empty;
    defer pending.deinit(gpa);
    for (gates.items) |g| {
        try pending.append(gpa, g);
    }
    var rounds: usize = 0;
    while (pending.items.len > 0 and rounds < 1000) : (rounds += 1) {
        var next: List(Gate) = .empty;
        defer next.deinit(gpa);
        for (pending.items) |g| {
            const a = vals.get(g.in1) orelse {
                try next.append(gpa, g);
                continue;
            };
            const b = vals.get(g.in2) orelse {
                try next.append(gpa, g);
                continue;
            };
            const v: u64 = switch (g.op) {
                'A' => a & b,
                'O' => a | b,
                else => a ^ b, // X
            };
            try vals.put(g.out, v);
        }
        if (next.items.len == pending.items.len) return error.Stuck;
        pending.clearRetainingCapacity();
        try pending.appendSlice(gpa, next.items);
    }
}

fn zValue(vals: *StrMap(u64)) u64 {
    var total: u64 = 0;
    var bit: u6 = 0;
    while (bit < 46) : (bit += 1) {
        var name_buf: [8]u8 = undefined;
        const name = std.fmt.bufPrint(&name_buf, "z{d:0>2}", .{bit}) catch break;
        const v = vals.get(name) orelse 0;
        if (v == 1) total |= @as(u64, 1) << bit;
    }
    return total;
}

fn xValue(vals: *StrMap(u64), which: u8) u64 {
    var total: u64 = 0;
    var bit: u6 = 0;
    while (bit < 46) : (bit += 1) {
        var name_buf: [8]u8 = undefined;
        const name = std.fmt.bufPrint(&name_buf, "{c}{d:0>2}", .{ which, bit }) catch break;
        const v = vals.get(name) orelse 0;
        if (v == 1) total |= @as(u64, 1) << bit;
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

var eval_buf: StrMap(u64) = undefined;

/// lowest incorrect z bit over all test vectors (99 = all correct); also
/// returns total wrong bits via pointer
fn circuitScore() struct { lowest: u8, wrong: usize } {
    var lowest: u8 = 99;
    var wrong_total: usize = 0;
    for (0..n_vecs) |t| {
        var vals = inputs.clone() catch return .{ .lowest = 99, .wrong = 999 };
        defer vals.deinit();
        var bit: u6 = 0;
        while (bit < 46) : (bit += 1) {
            var buf: [8]u8 = undefined;
            const xn = std.fmt.bufPrint(&buf, "x{d:0>2}", .{bit}) catch break;
            vals.put(xn, (test_x[t] >> bit) & 1) catch {};
            var buf2: [8]u8 = undefined;
            const yn = std.fmt.bufPrint(&buf2, "y{d:0>2}", .{bit}) catch break;
            vals.put(yn, (test_y[t] >> bit) & 1) catch {};
        }
        evalAll(&vals) catch return .{ .lowest = 99, .wrong = 999 };
        const expected = test_x[t] + test_y[t];
        const z = zValue(&vals);
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
            try inputs.put(line[0..colon], try parseInt(u64, line[colon + 2 ..], 10));
        } else {
            var it = tokenizeSca(u8, line, ' ');
            const in1 = try std.heap.page_allocator.dupe(u8, it.next().?);
            const op_raw = it.next().?;
            const in2 = try std.heap.page_allocator.dupe(u8, it.next().?);
            _ = it.next().?; // ->
            const out = try std.heap.page_allocator.dupe(u8, it.next().?);
            try gates.append(gpa, .{ .in1 = in1, .in2 = in2, .op = op_raw[0], .out = out });
        }
    }

    // part 1
    {
        var vals = try inputs.clone();
        defer vals.deinit();
        try evalAll(&vals);
        print("part 1: {d}\n", .{zValue(&vals)});
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
                // find gates in the fan-in cone of `target` (up to full depth)
                var queue: List([]const u8) = .empty;
                defer queue.deinit(gpa);
                try queue.append(gpa, target);
                var depth: usize = 0;
                while (queue.items.len > 0 and depth < 200) : (depth += 1) {
                    const w = queue.pop().?;
                    for (gates.items, 0..) |g, gi| {
                        if (std.mem.eql(u8, g.out, w)) {
                            if (!cone.contains(gi)) {
                                try cone.put(gi, {});
                                try queue.append(gpa, g.in1);
                                try queue.append(gpa, g.in2);
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
                    // at least one gate in the cone
                    if (!cone.contains(i) and !cone.contains(j)) continue;
                    const tmp = gi.out;
                    gi.out = gj.out;
                    gj.out = tmp;
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
                    const tmp2 = gi.out;
                    gi.out = gj.out;
                    gj.out = tmp2;
                }
            }
            if (!found) {
                print("part 2: stuck at round {d}\n", .{round});
                break;
            }
            const tmp = gates.items[best_i].out;
            gates.items[best_i].out = gates.items[best_j].out;
            gates.items[best_j].out = tmp;
            try swapped.append(gpa, gates.items[best_i].out);
            try swapped.append(gpa, gates.items[best_j].out);
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
