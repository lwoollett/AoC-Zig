const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day24.txt");

fn biodiversity(bits: u32) u64 {
    var total: u64 = 0;
    for (0..25) |i| {
        if ((bits >> @intCast(i)) & 1 == 1) total += @as(u64, 1) << @intCast(i);
    }
    return total;
}

pub fn main() !void {
    var initial: u32 = 0;
    {
        var lines = tokenizeAny(u8, data, "\n");
        var y: u5 = 0;
        while (lines.next()) |line| : (y += 1) {
            for (line, 0..) |c, x| {
                if (c == '#') initial |= @as(u32, 1) << @intCast(y * 5 + x);
            }
        }
    }

    // part 1: flat simulation until repeat
    {
        var seen = Map(u32, void).init(gpa);
        defer seen.deinit();
        var state = initial;
        while (!seen.contains(state)) {
            try seen.put(state, {});
            var next: u32 = 0;
            for (0..25) |i| {
                const x: i32 = @intCast(i % 5);
                const yy: i32 = @intCast(i / 5);
                var nb: u32 = 0;
                const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
                for (deltas) |dl| {
                    const nx = x + dl[0];
                    const ny = yy + dl[1];
                    if (nx < 0 or ny < 0 or nx >= 5 or ny >= 5) continue;
                    const idx: u5 = @intCast(ny * 5 + nx);
                    if ((state >> idx) & 1 == 1) nb += 1;
                }
                const bug = (state >> @intCast(i)) & 1 == 1;
                const stays = if (bug) nb == 1 else (nb == 1 or nb == 2);
                if (stays) next |= @as(u32, 1) << @intCast(i);
            }
            state = next;
        }
        print("part 1: {d}\n", .{biodiversity(state)});
    }

    // part 2: recursive levels, 200 minutes
    {
        var levels = Map(i32, u32).init(gpa);
        defer levels.deinit();
        try levels.put(0, initial);

        var minute: usize = 0;
        while (minute < 200) : (minute += 1) {
            var next_levels = Map(i32, u32).init(gpa);
            // active levels: existing +/- 1
            var active = Map(i32, void).init(gpa);
            defer active.deinit();
            var it = levels.keyIterator();
            while (it.next()) |k| {
                try active.put(k.*, {});
                try active.put(k.* - 1, {});
                try active.put(k.* + 1, {});
            }
            var ait = active.keyIterator();
            while (ait.next()) |lvl| {
                var next: u32 = 0;
                for (0..25) |i| {
                    if (i == 12) continue; // center is always empty
                    const x: i32 = @intCast(i % 5);
                    const yy: i32 = @intCast(i / 5);
                    var nb: u32 = 0;
                    // same-level neighbors
                    const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
                    for (deltas) |dl| {
                        const nx = x + dl[0];
                        const ny = yy + dl[1];
                        if (nx < 0 or ny < 0 or nx >= 5 or ny >= 5) continue;
                        const idx: u5 = @intCast(ny * 5 + nx);
                        if (idx == 12) {
                            // neighbor is the center: look one level deeper
                            const deeper = levels.get(lvl.* + 1) orelse 0;
                            nb += innerNeighbors(deeper, x, yy);
                        } else {
                            const cur = levels.get(lvl.*) orelse 0;
                            if ((cur >> idx) & 1 == 1) nb += 1;
                        }
                    }
                    // recursive edge neighbors (level - 1)
                    const outer = levels.get(lvl.* - 1) orelse 0;
                    nb += outerNeighbors(outer, x, yy);
                    const cur = levels.get(lvl.*) orelse 0;
                    const bug = (cur >> @intCast(i)) & 1 == 1;
                    const stays = if (bug) nb == 1 else (nb == 1 or nb == 2);
                    if (stays) next |= @as(u32, 1) << @intCast(i);
                }
                if (next != 0) try next_levels.put(lvl.*, next);
            }
            levels.deinit();
            levels = next_levels;
        }
        var total: usize = 0;
        var vit = levels.valueIterator();
        while (vit.next()) |v| total += @popCount(v.*);
        print("part 2: {d}\n", .{total});
    }
}

/// Count bugs in `deeper` level adjacent to cell (x, y) of the outer level,
/// where (x, y) is one of the 8 cells touching the center.
fn innerNeighbors(deeper: u32, x: i32, y: i32) u32 {
    var n: u32 = 0;
    if (x == 2 and y == 1) {
        // cell above center: neighbors = top row of deeper
        var i: u5 = 0;
        while (i < 5) : (i += 1) {
            if ((deeper >> i) & 1 == 1) n += 1;
        }
    } else if (x == 2 and y == 3) {
        var i: u5 = 20;
        while (i < 25) : (i += 1) {
            if ((deeper >> i) & 1 == 1) n += 1;
        }
    } else if (x == 1 and y == 2) {
        var i: u5 = 0;
        while (i < 25) : (i += 5) {
            if ((deeper >> i) & 1 == 1) n += 1;
        }
    } else if (x == 3 and y == 2) {
        var i: u5 = 4;
        while (i < 25) : (i += 5) {
            if ((deeper >> i) & 1 == 1) n += 1;
        }
    }
    return n;
}

/// Count bugs in `outer` level adjacent to edge cell (x, y).
fn outerNeighbors(outer: u32, x: i32, y: i32) u32 {
    var n: u32 = 0;
    if (y == 0) {
        if ((outer >> @intCast(1 * 5 + 2)) & 1 == 1) n += 1; // (2,1) above center
    }
    if (y == 4) {
        if ((outer >> @intCast(3 * 5 + 2)) & 1 == 1) n += 1; // (2,3) below center
    }
    if (x == 0) {
        if ((outer >> @intCast(2 * 5 + 1)) & 1 == 1) n += 1; // (1,2) left of center
    }
    if (x == 4) {
        if ((outer >> @intCast(2 * 5 + 3)) & 1 == 1) n += 1; // (3,2) right of center
    }
    return n;
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
