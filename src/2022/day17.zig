const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day17.txt");

/// rows[0] is the floor-adjacent row; bit x set = rock at (x, row)
var rows: List(u8) = .empty;

const Rock = struct {
    cells: []const [2]u8, // (x, y) offsets, y=0 bottom
    w: u8,
    h: u8,
};

const rocks = [_]Rock{
    .{ .cells = &.{ .{ 0, 0 }, .{ 1, 0 }, .{ 2, 0 }, .{ 3, 0 } }, .w = 4, .h = 1 },
    .{ .cells = &.{ .{ 1, 0 }, .{ 0, 1 }, .{ 1, 1 }, .{ 2, 1 }, .{ 1, 2 } }, .w = 3, .h = 3 },
    .{ .cells = &.{ .{ 0, 0 }, .{ 1, 0 }, .{ 2, 0 }, .{ 2, 1 }, .{ 2, 2 } }, .w = 3, .h = 3 },
    .{ .cells = &.{ .{ 0, 0 }, .{ 0, 1 }, .{ 0, 2 }, .{ 0, 3 } }, .w = 1, .h = 4 },
    .{ .cells = &.{ .{ 0, 0 }, .{ 1, 0 }, .{ 0, 1 }, .{ 1, 1 } }, .w = 2, .h = 2 },
};

const jets = data; // trimmed below

fn fits(rock: Rock, px: i32, py: i32) bool {
    // py = bottom row index of the rock (absolute, may be negative while above)
    for (rock.cells) |c| {
        const x = px + c[0];
        const y = py + c[1];
        if (x < 0 or x > 6) return false;
        if (y < 0) return false; // the chamber floor
        if (y >= rows.items.len) continue; // above all settled rocks
        if ((rows.items[@intCast(y)] >> @intCast(x)) & 1 == 1) return false;
    }
    return true;
}

fn place(rock: Rock, px: i32, py: i32) void {
    while (rows.items.len < py + rock.h) {
        rows.append(gpa, 0) catch unreachable;
    }
    for (rock.cells) |c| {
        const x = px + c[0];
        const y = py + c[1];
        rows.items[@intCast(y)] |= @as(u8, 1) << @intCast(x);
    }
}

const StateKey = struct { rock_mod: u8, jet: usize, profile: u64 };

fn simulate(total_rocks: u64) !u64 {
    rows.clearRetainingCapacity();
    const jet_pattern = trim(u8, jets, " \n\r\t");
    var jet_idx: usize = 0;
    var rock_i: u64 = 0;

    var seen = Map(StateKey, struct { rocks: u64, height: u64 }).init(gpa);
    defer seen.deinit();

    var pre_cycles_height: u64 = 0;
    var cycle_height_gain: u64 = 0;
    var cycle_rock_len: u64 = 0;
    var skipped = false;

    while (rock_i < total_rocks) : (rock_i += 1) {
        const rock = rocks[rock_i % 5];

        // top profile: 8 rows
        var profile: u64 = 0;
        const top = rows.items.len;
        for (0..8) |k| {
            const v = if (k < top) rows.items[top - 1 - k] else 0;
            profile |= @as(u64, v) << @intCast(k * 8);
        }
        const key = StateKey{ .rock_mod = @intCast(rock_i % 5), .jet = jet_idx, .profile = profile };

        if (!skipped) {
            if (seen.get(key)) |prev| {
                // cycle found: project only the GAIN — rows.items.len at
                // the end already contains the skip-point height
                cycle_rock_len = rock_i - prev.rocks;
                cycle_height_gain = top - prev.height;
                const remaining = total_rocks - rock_i;
                const full_cycles = remaining / cycle_rock_len;
                pre_cycles_height = full_cycles * cycle_height_gain;
                rock_i += full_cycles * cycle_rock_len;
                skipped = true;
                if (rock_i >= total_rocks) break;
                rock_i -= 1; // the loop increment on continue must not skip a rock
                continue;
            }
            try seen.put(key, .{ .rocks = rock_i, .height = top });
        }

        // spawn
        var px: i32 = 2;
        var py: i32 = @as(i32, @intCast(rows.items.len)) + 3;
        while (true) {
            // jet push
            const dir: i32 = if (jet_pattern[jet_idx] == '<') -1 else 1;
            jet_idx = (jet_idx + 1) % jet_pattern.len;
            if (fits(rock, px + dir, py)) px += dir;
            // fall
            if (fits(rock, px, py - 1)) {
                py -= 1;
            } else {
                place(rock, px, py);
                break;
            }
        }
    }
    return pre_cycles_height + rows.items.len;
}

pub fn main() !void {
    print("part 1: {d}\n", .{try simulate(2022)});
    print("part 2: {d}\n", .{try simulate(1_000_000_000_000)});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;
