const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day23.txt");

// state encoding: hallway[11] then rooms[4][depth] (0 = empty, 1..4 = A..D)
const state_len = 11 + 16;
const State = [state_len]u8;

const room_col = [4]u8{ 2, 4, 6, 8 };
var depth: usize = 2;

fn isSolved(s: *const State) bool {
    for (0..4) |r| {
        for (0..depth) |d| {
            if (s[11 + r * 4 + d] != r + 1) return false;
        }
    }
    return true;
}

/// hallway path clear between a and b (exclusive both ends)
fn hallClear(s: *const State, a: usize, b: usize) bool {
    const lo = @min(a, b);
    const hi = @max(a, b);
    var i = lo + 1;
    while (i < hi) : (i += 1) {
        if (s[i] != 0) return false;
    }
    return true;
}

/// steps from hallway cell c into room r slot d (0 = top)
fn hallToRoomSteps(c: usize, r: usize, d: usize) usize {
    const col = room_col[r];
    const dc: usize = if (c > col) c - col else col - c;
    return dc + 1 + d;
}

const Move = struct { cost: u64, next: State };

fn genMoves(s: *const State, out: *List(Move)) !void {
    // hallway -> room
    for (0..11) |c| {
        const t = s[c];
        if (t == 0) continue;
        const r = t - 1; // target room index
        // room must contain only its own type
        var ok = true;
        for (0..depth) |d| {
            const v = s[11 + r * 4 + d];
            if (v != 0 and v != t) ok = false;
        }
        if (!ok) continue;
        // find the deepest empty slot
        var slot: ?usize = null;
        for (0..depth) |d| {
            if (s[11 + r * 4 + d] == 0) slot = d;
        }
        if (slot == null) continue;
        // path from c to room col must be clear
        if (!hallClear(s, c, room_col[r])) continue;
        var ns = s.*;
        ns[c] = 0;
        ns[11 + r * 4 + slot.?] = t;
        const steps = hallToRoomSteps(c, r, slot.?);
        try out.append(gpa, .{
            .cost = steps * @as(u64, std.math.pow(u64, 10, t - 1)),
            .next = ns,
        });
    }

    // room -> hallway
    for (0..4) |r| {
        // topmost occupant
        var d: usize = 0;
        while (d < depth and s[11 + r * 4 + d] == 0) d += 1;
        if (d == depth) continue; // empty room
        const t = s[11 + r * 4 + d];
        // prune: if this amphipod is home and all below are same type, never move
        if (r == t - 1) {
            var settled = true;
            var dd = d;
            while (dd < depth) : (dd += 1) {
                if (s[11 + r * 4 + dd] != t) settled = false;
            }
            if (settled) continue;
        }
        // path from room entrance to each hallway cell
        for (0..11) |c| {
            if (c == 2 or c == 4 or c == 6 or c == 8) continue; // no parking at entrances
            if (s[c] != 0) continue;
            if (!hallClear(s, room_col[r], c)) continue;
            var ns = s.*;
            ns[11 + r * 4 + d] = 0;
            ns[c] = t;
            const steps = hallToRoomSteps(c, r, d);
            try out.append(gpa, .{
                .cost = steps * @as(u64, std.math.pow(u64, 10, t - 1)),
                .next = ns,
            });
        }
    }
}

fn solve(start: *const State) !u64 {
    const Item = struct { cost: u64, state: State };
    var pq = std.PriorityQueue(Item, void, struct {
        fn lessThan(_: void, a: Item, b: Item) std.math.Order {
            return std.math.order(a.cost, b.cost);
        }
    }.lessThan).initContext({});
    defer pq.deinit(gpa);

    var best = Map(State, u64).init(gpa);
    defer best.deinit();

    try pq.push(gpa, .{ .cost = 0, .state = start.* });
    try best.put(start.*, 0);

    var moves: List(Move) = .empty;
    defer moves.deinit(gpa);
    while (pq.pop()) |cur| {
        if (cur.cost > (best.get(cur.state) orelse std.math.maxInt(u64))) continue;
        if (isSolved(&cur.state)) return cur.cost;
        moves.clearRetainingCapacity();
        try genMoves(&cur.state, &moves);
        for (moves.items) |m| {
            const nc = cur.cost + m.cost;
            const prev = best.get(m.next) orelse std.math.maxInt(u64);
            if (nc < prev) {
                try best.put(m.next, nc);
                try pq.push(gpa, .{ .cost = nc, .state = m.next });
            }
        }
    }
    return error.NoSolution;
}

pub fn main() !void {
    // parse the two room-content lines
    var l1: [4]u8 = undefined;
    var l2: [4]u8 = undefined;
    {
        var lines = tokenizeAny(u8, data, "\n");
        var rows: usize = 0;
        while (lines.next()) |line| {
            var letters: usize = 0;
            for (line) |c| {
                if (c >= 'A' and c <= 'D') letters += 1;
            }
            if (letters == 4) {
                var idx: usize = 0;
                if (rows == 0) {
                    for (line) |c| {
                        if (c >= 'A' and c <= 'D') {
                            l1[idx] = c - 'A' + 1;
                            idx += 1;
                        }
                    }
                } else {
                    for (line) |c| {
                        if (c >= 'A' and c <= 'D') {
                            l2[idx] = c - 'A' + 1;
                            idx += 1;
                        }
                    }
                }
                rows += 1;
            }
        }
    }

    // part 1: depth 2
    {
        depth = 2;
        var st: State = @splat(0);
        for (0..4) |r| {
            st[11 + r * 4 + 0] = l1[r];
            st[11 + r * 4 + 1] = l2[r];
        }
        print("part 1: {d}\n", .{try solve(&st)});
    }

    // part 2: depth 4 with the fixed inserted rows
    {
        depth = 4;
        var st: State = @splat(0);
        const mid1 = [4]u8{ 4, 3, 2, 1 }; // D C B A
        const mid2 = [4]u8{ 4, 2, 1, 3 }; // D B A C
        for (0..4) |r| {
            st[11 + r * 4 + 0] = l1[r];
            st[11 + r * 4 + 1] = mid1[r];
            st[11 + r * 4 + 2] = mid2[r];
            st[11 + r * 4 + 3] = l2[r];
        }
        print("part 2: {d}\n", .{try solve(&st)});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
