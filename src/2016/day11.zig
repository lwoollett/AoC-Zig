const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day11.txt");

const max_pairs = 8;

const State = struct {
    elevator: u8,
    pairs: [max_pairs][2]u8, // [chip floor, gen floor]
    n: u8,
};

fn stateKey(alloc: std.mem.Allocator, s: *const State) ![]u8 {
    // canonical: sort pair encoding numerically
    var enc: [max_pairs]u16 = @splat(0);
    for (s.pairs[0..s.n], 0..) |p, i| {
        enc[i] = @as(u16, p[0]) * 4 + p[1];
    }
    std.mem.sort(u16, enc[0..s.n], {}, comptime std.sort.asc(u16));
    var buf: [1 + max_pairs * 2]u8 = undefined;
    buf[0] = s.elevator;
    for (enc[0..s.n], 0..) |e, i| {
        buf[1 + i * 2] = @intCast(e / 4);
        buf[2 + i * 2] = @intCast(e % 4);
    }
    return alloc.dupe(u8, buf[0 .. 1 + @as(usize, s.n) * 2]);
}

fn floorsSafe(s: *const State, floor: u8, skip: ?usize) bool {
    // For the given floor, check: any chip on it without its gen means no gen may be there.
    _ = skip;
    var has_gen: [max_pairs]bool = @splat(false);
    var has_chip: [max_pairs]bool = @splat(false);
    var any_gen = false;
    var any_chip = false;
    for (s.pairs[0..s.n], 0..) |p, i| {
        if (p[1] == floor) {
            has_gen[i] = true;
            any_gen = true;
        }
        if (p[0] == floor) {
            has_chip[i] = true;
            any_chip = true;
        }
    }
    if (!any_gen) return true;
    for (has_chip, 0..) |chip, i| {
        if (chip and !has_gen[i]) return false;
    }
    return true;
}

fn solved(s: *const State) bool {
    for (s.pairs[0..s.n]) |p| {
        if (p[0] != 3 or p[1] != 3) return false;
    }
    return true;
}

fn solve(start: State) !u32 {
    var visited = StrMap(void).init(gpa);
    defer visited.deinit();

    var frontier: List(State) = .empty;
    defer frontier.deinit(gpa);
    var next: List(State) = .empty;
    defer next.deinit(gpa);

    try frontier.append(gpa, start);
    {
        // The map owns its keys — no free here.
        const key = try stateKey(gpa, &start);
        try visited.put(key, {});
    }

    var steps: u32 = 0;
    while (frontier.items.len > 0) {
        steps += 1;
        next.clearRetainingCapacity();
        for (frontier.items) |cur| {
            // items on the elevator's floor: (pair index, kind 0=chip 1=gen)
            var items: [max_pairs * 2]u8 = undefined;
            var kinds: [max_pairs * 2]u8 = undefined;
            var n_items: usize = 0;
            for (cur.pairs[0..cur.n], 0..) |p, i| {
                if (p[0] == cur.elevator) {
                    items[n_items] = @intCast(i);
                    kinds[n_items] = 0;
                    n_items += 1;
                }
                if (p[1] == cur.elevator) {
                    items[n_items] = @intCast(i);
                    kinds[n_items] = 1;
                    n_items += 1;
                }
            }

            const dirs = [2]i8{ 1, -1 };
            for (dirs) |dir| {
                const nf = @as(i16, cur.elevator) + dir;
                if (nf < 0 or nf > 3) continue;
                const new_floor: u8 = @intCast(nf);

                // move 1 or 2 items
                var a: usize = 0;
                while (a < n_items) : (a += 1) {
                    var b: usize = a;
                    while (b < n_items) : (b += 1) {
                        // skip duplicate (a,b) pairs when a==b handled once
                        var cand = cur;
                        cand.elevator = new_floor;
                        // move item(s) from cur.elevator to new_floor
                        const apply = struct {
                            fn f(s: *State, pair: u8, kind: u8, to: u8) void {
                                s.pairs[pair][kind] = to;
                            }
                        }.f;
                        apply(&cand, items[a], kinds[a], new_floor);
                        if (b != a) apply(&cand, items[b], kinds[b], new_floor);

                        if (!floorsSafe(&cand, cur.elevator, null)) continue;
                        if (!floorsSafe(&cand, new_floor, null)) continue;

                        if (solved(&cand)) return steps;

                        const key = try stateKey(gpa, &cand);
                        if (!visited.contains(key)) {
                            try visited.put(key, {});
                            try next.append(gpa, cand);
                        } else {
                            gpa.free(key);
                        }
                    }
                }
            }
        }
        std.mem.swap(List(State), &frontier, &next);
    }
    return error.NoSolution;
}

pub fn main() !void {
    // Parse: element names to pair indices; floors 0..3.
    var names = StrMap(u8).init(gpa);
    defer names.deinit();
    var start: State = .{ .elevator = 0, .pairs = @splat(.{ 0, 0 }), .n = 0 };

    // Token scan for "first/second/third/fourth" floor markers and
    // "<element> generator" / "<element>-compatible microchip" items.
    var it = tokenizeAny(u8, data, " .,\n");
    var toks: [512][]const u8 = undefined;
    var n_toks: usize = 0;
    while (it.next()) |t| {
        toks[n_toks] = t;
        n_toks += 1;
    }
    var floor_of_line: u8 = 0;
    var tok_i: usize = 0;
    while (tok_i < n_toks) : (tok_i += 1) {
        const t = toks[tok_i];
        const fl: ?u8 = if (std.mem.eql(u8, t, "first"))
            0
        else if (std.mem.eql(u8, t, "second"))
            1
        else if (std.mem.eql(u8, t, "third"))
            2
        else if (std.mem.eql(u8, t, "fourth"))
            3
        else
            null;
        if (fl) |f| {
            floor_of_line = f;
            continue;
        }
        if (std.mem.eql(u8, t, "generator")) {
            const name = toks[tok_i - 1];
            const idx = try pairIndex(&names, name, &start);
            start.pairs[idx][1] = floor_of_line;
        } else if (std.mem.eql(u8, t, "microchip")) {
            const name = toks[tok_i - 1]; // "X-compatible"
            const base = name[0..std.mem.findScalar(u8, name, '-').?];
            const idx = try pairIndex(&names, base, &start);
            start.pairs[idx][0] = floor_of_line;
        }
    }

    print("part 1: {d}\n", .{try solve(start)});

    // Part 2: elerium + dilithium chip & generator start on floor 0.
    var start2 = start;
    start2.n += 2;
    start2.pairs[start.n] = .{ 0, 0 };
    start2.pairs[start.n + 1] = .{ 0, 0 };
    print("part 2: {d}\n", .{try solve(start2)});
}

fn pairIndex(names: *StrMap(u8), name: []const u8, start: *State) !u8 {
    if (names.get(name)) |i| return i;
    const i = start.n;
    start.n += 1;
    try names.put(name, i);
    return i;
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
