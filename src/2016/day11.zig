const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


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
    // one arena for the whole search: the BFS makes millions of tiny
    // allocations (state keys, map growth), and page-per-alloc mmap churn
    // dominates runtime — bulk arena pages are 10x cheaper
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var visited = StrMap(void).init(alloc);
    defer visited.deinit();

    var frontier: List(State) = .empty;
    defer frontier.deinit(alloc);
    var next: List(State) = .empty;
    defer next.deinit(alloc);

    try frontier.append(alloc, start);
    {
        // The map owns its keys — no free here.
        const key = try stateKey(alloc, &start);
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

                        const key = try stateKey(alloc, &cand);
                        if (!visited.contains(key)) {
                            try visited.put(key, {});
                            try next.append(alloc, cand);
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

    // Part 2: elerium + dilithium chip & generator start on floor 0.
    var start2 = start;
    start2.n += 2;
    start2.pairs[start.n] = .{ 0, 0 };
    start2.pairs[start.n + 1] = .{ 0, 0 };

    // the two searches are independent — run them concurrently
    var r1: u32 = 0;
    var r2: u32 = 0;
    const t = try std.Thread.spawn(.{}, solvePart, .{ start2, &r2 }); // p2 has the bigger space
    r1 = try solve(start);
    t.join();
    print("part 1: {d}\n", .{r1});
    print("part 2: {d}\n", .{r2});
}

fn solvePart(start: State, out: *u32) void {
    out.* = solve(start) catch 0;
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
const print = std.debug.print;
const sort = std.sort.block;
const asc = std.sort.asc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
