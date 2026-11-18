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

const P = struct { x: i32, y: i32 };

const gw = 130;
const gh = 130;

const Portal = struct { tag: [2]u8, pad: P, outer: bool };

fn parsePortals(grid: [gh][gw]u8, w: i32, h: i32, portals: *List(Portal)) !void {
    var y: i32 = 0;
    while (y < h) : (y += 1) {
        var x: i32 = 0;
        while (x < w) : (x += 1) {
            const c1 = grid[@intCast(y)][@intCast(x)];
            if (c1 < 'A' or c1 > 'Z') continue;
            // outer = pad sits within the maze's outer ring (2 cells from
            // the grid border); inner = deep inside
            const isOuter = struct {
                fn f(px: i32, py: i32, ww: i32, hh: i32) bool {
                    return px <= 2 or px >= ww - 3 or py <= 2 or py >= hh - 3;
                }
            }.f;
            // horizontal pair?
            if (x + 1 < w) {
                const c2 = grid[@intCast(y)][@intCast(x + 1)];
                if (c2 >= 'A' and c2 <= 'Z') {
                    if (x - 1 >= 0 and grid[@intCast(y)][@intCast(x - 1)] == '.') {
                        try portals.append(gpa, .{ .tag = .{ c1, c2 }, .pad = .{ .x = x - 1, .y = y }, .outer = isOuter(x - 1, y, w, h) });
                    } else if (x + 2 < w and grid[@intCast(y)][@intCast(x + 2)] == '.') {
                        try portals.append(gpa, .{ .tag = .{ c1, c2 }, .pad = .{ .x = x + 2, .y = y }, .outer = isOuter(x + 2, y, w, h) });
                    }
                }
            }
            // vertical pair?
            if (y + 1 < h) {
                const c2 = grid[@intCast(y + 1)][@intCast(x)];
                if (c2 >= 'A' and c2 <= 'Z') {
                    if (y - 1 >= 0 and grid[@intCast(y - 1)][@intCast(x)] == '.') {
                        try portals.append(gpa, .{ .tag = .{ c1, c2 }, .pad = .{ .x = x, .y = y - 1 }, .outer = isOuter(x, y - 1, w, h) });
                    } else if (y + 2 < h and grid[@intCast(y + 2)][@intCast(x)] == '.') {
                        try portals.append(gpa, .{ .tag = .{ c1, c2 }, .pad = .{ .x = x, .y = y + 2 }, .outer = isOuter(x, y + 2, w, h) });
                    }
                }
            }
        }
    }
}

fn findPortal(portals: []const Portal, at: P) ?*const Portal {
    for (portals) |*p| {
        if (p.pad.x == at.x and p.pad.y == at.y) return p;
    }
    return null;
}

fn warpTarget(portals: []const Portal, from: *const Portal) ?P {
    for (portals) |*p| {
        if (p.tag[0] == from.tag[0] and p.tag[1] == from.tag[1] and
            (p.pad.x != from.pad.x or p.pad.y != from.pad.y))
        {
            return p.pad;
        }
    }
    return null;
}

const State = struct { pos: P, level: i32 };

pub fn main() !void {
    var grid: [gh][gw]u8 = @splat(@splat('#'));
    var w: i32 = 0;
    var h: i32 = 0;
    {
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            @memcpy(grid[@intCast(h)][0..line.len], line);
            w = @max(w, @as(i32, @intCast(line.len)));
            h += 1;
        }
    }

    var portals: List(Portal) = .empty;
    defer portals.deinit(gpa);
    try parsePortals(grid, w, h, &portals);

    // find AA and ZZ
    var aa: Portal = portals.items[0];
    var zz: Portal = portals.items[0];
    for (portals.items) |p| {
        if (p.tag[0] == 'A' and p.tag[1] == 'A') aa = p;
        if (p.tag[0] == 'Z' and p.tag[1] == 'Z') zz = p;
    }

    // BFS part 1: flat maze
    {
        var dist = Map(P, u32).init(gpa);
        defer dist.deinit();
        var q: List(P) = .empty;
        defer q.deinit(gpa);
        try dist.put(aa.pad, 0);
        try q.append(gpa, aa.pad);
        var head: usize = 0;
        var found: ?u32 = null;
        while (head < q.items.len) : (head += 1) {
            const cur = q.items[head];
            const d = dist.get(cur).?;
            if (cur.x == zz.pad.x and cur.y == zz.pad.y) {
                found = d;
                break;
            }
            var neighbors: [4]P = undefined;
            var nn: usize = 0;
            const deltas = [4]P{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 1 }, .{ .x = -1, .y = 0 }, .{ .x = 1, .y = 0 } };
            for (deltas) |dl| {
                neighbors[nn] = .{ .x = cur.x + dl.x, .y = cur.y + dl.y };
                nn += 1;
            }
            // portal warp
            if (findPortal(portals.items, cur)) |p| {
                if (!(p.tag[0] == 'A' and p.tag[1] == 'A') and !(p.tag[0] == 'Z' and p.tag[1] == 'Z')) {
                    if (warpTarget(portals.items, p)) |t| {
                        // entering the pad cell counts; stepping through warp
                        if (!dist.contains(t)) {
                            try dist.put(t, d + 1);
                            try q.append(gpa, t);
                        }
                    }
                }
            }
            for (neighbors[0..nn]) |np| {
                if (np.x < 0 or np.y < 0 or np.x >= w or np.y >= h) continue;
                const cell = grid[@intCast(np.y)][@intCast(np.x)];
                if (cell == '#' or (cell >= 'A' and cell <= 'Z')) continue;
                if (dist.contains(np)) continue;
                try dist.put(np, d + 1);
                try q.append(gpa, np);
            }
        }
        print("part 1: {d}\n", .{found.?});
    }

    // BFS part 2: recursive levels
    {
        var dist = Map(State, u32).init(gpa);
        defer dist.deinit();
        var q: List(State) = .empty;
        defer q.deinit(gpa);
        try dist.put(.{ .pos = aa.pad, .level = 0 }, 0);
        try q.append(gpa, .{ .pos = aa.pad, .level = 0 });
        var head: usize = 0;
        var found: ?u32 = null;
        while (head < q.items.len) : (head += 1) {
            const cur = q.items[head];
            const d = dist.get(cur).?;
            if (cur.level == 0 and cur.pos.x == zz.pad.x and cur.pos.y == zz.pad.y) {
                found = d;
                break;
            }
            const deltas = [4]P{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 1 }, .{ .x = -1, .y = 0 }, .{ .x = 1, .y = 0 } };
            for (deltas) |dl| {
                const np = P{ .x = cur.pos.x + dl.x, .y = cur.pos.y + dl.y };
                if (np.x < 0 or np.y < 0 or np.x >= w or np.y >= h) continue;
                const cell = grid[@intCast(np.y)][@intCast(np.x)];
                if (cell == '#' or (cell >= 'A' and cell <= 'Z')) continue;
                const ns = State{ .pos = np, .level = cur.level };
                if (!dist.contains(ns)) {
                    try dist.put(ns, d + 1);
                    try q.append(gpa, ns);
                }
            }
            // portal warp with levels
            if (findPortal(portals.items, cur.pos)) |p| {
                const is_aa = p.tag[0] == 'A' and p.tag[1] == 'A';
                const is_zz = p.tag[0] == 'Z' and p.tag[1] == 'Z';
                if (!is_aa and !is_zz) {
                    if (warpTarget(portals.items, p)) |t| {
                        const new_level = if (p.outer) cur.level - 1 else cur.level + 1;
                        if (new_level >= 0) {
                            const ns = State{ .pos = t, .level = new_level };
                            if (!dist.contains(ns)) {
                                try dist.put(ns, d + 1);
                                try q.append(gpa, ns);
                            }
                        }
                    }
                }
            }
        }
        print("part 2: {d}\n", .{found.?});
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
