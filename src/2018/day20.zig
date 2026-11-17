const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day20.txt");

const P = [2]i32;

/// doors: midpoint between two rooms, hashed as x*100000+y
fn doorKey(a: P, b: P) i64 {
    // raw coordinate sums: odd on the door's axis, even on the other — unique
    return @as(i64, a[0] + b[0]) * 4_000_000 + @as(i64, a[1] + b[1]);
}

pub fn main() !void {
    var doors = Map(i64, void).init(gpa);
    defer doors.deinit();

    var cur = Map(P, void).init(gpa);
    defer cur.deinit();
    try cur.put(.{ 0, 0 }, {});

    // stack for branch points: (saved base set, accumulated alternatives)
    var bases: List(Map(P, void)) = .empty;
    var accs: List(Map(P, void)) = .empty;

    const regex = trim(u8, data, " \n\r\t");
    for (regex) |c| {
        switch (c) {
            '^', '$' => {},
            'N', 'S', 'E', 'W' => {
                const d: P = switch (c) {
                    'N' => .{ 0, -1 },
                    'S' => .{ 0, 1 },
                    'E' => .{ 1, 0 },
                    else => .{ -1, 0 },
                };
                var next = Map(P, void).init(gpa);
                var it = cur.keyIterator();
                while (it.next()) |kp| {
                    const np = P{ kp.*[0] + d[0], kp.*[1] + d[1] };
                    try doors.put(doorKey(kp.*, np), {});
                    try next.put(np, {});
                }
                cur.deinit();
                cur = next;
            },
            '(' => {
                try bases.append(gpa, cur);
                try accs.append(gpa, Map(P, void).init(gpa));
                cur = try cloneSet(cur);
            },
            '|' => {
                // fold current into the accumulator, restart from the base
                var acc = accs.items[accs.items.len - 1];
                var it = cur.keyIterator();
                while (it.next()) |kp| {
                    try acc.put(kp.*, {});
                }
                cur.deinit();
                cur = try cloneSet(bases.items[bases.items.len - 1]);
            },
            ')' => {
                var acc = accs.pop().?;
                var it = cur.keyIterator();
                while (it.next()) |kp| {
                    try acc.put(kp.*, {});
                }
                cur.deinit();
                cur = acc;
                _ = bases.pop();
            },
            else => {},
        }
    }

    // BFS from (0,0) through doors.
    var dist = Map(P, u32).init(gpa);
    defer dist.deinit();
    try dist.put(.{ 0, 0 }, 0);
    var queue: List(P) = .empty;
    defer queue.deinit(gpa);
    try queue.append(gpa, .{ 0, 0 });
    var qi: usize = 0;
    var farthest: u32 = 0;
    var over_1000: u32 = 0;
    while (qi < queue.items.len) : (qi += 1) {
        const p = queue.items[qi];
        const d = dist.get(p).?;
        farthest = @max(farthest, d);
        if (d >= 1000) over_1000 += 1;
        const dirs = [4]P{ .{ 0, -1 }, .{ 0, 1 }, .{ 1, 0 }, .{ -1, 0 } };
        for (dirs) |dd| {
            const np = P{ p[0] + dd[0], p[1] + dd[1] };
            if (dist.contains(np)) continue;
            if (!doors.contains(doorKey(p, np))) continue;
            try dist.put(np, d + 1);
            try queue.append(gpa, np);
        }
    }

    print("part 1: {d}\n", .{farthest});
    print("part 2: {d}\n", .{over_1000});
}

fn cloneSet(src: Map(P, void)) !Map(P, void) {
    var out = Map(P, void).init(gpa);
    var it = src.keyIterator();
    while (it.next()) |kp| {
        try out.put(kp.*, {});
    }
    return out;
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
