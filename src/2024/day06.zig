const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day06.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat('.'));
var h: usize = 0;
var w: usize = 0;

// flat state tracking: (y*w + x)*4 + dir; generation counters avoid clears
var seen_states: []u32 = &.{};
var visited_cells: []bool = &.{};
var generation: u32 = 0;

const Step = struct { x: u8, y: u8, dir: u8, nx: u8, ny: u8 };
var base_path: List(Step) = .empty;

/// Walk the patrol from (x, y, dir); records the unobstructed route.
fn walk(x0: usize, y0: usize, dir0: u8, record: bool) bool {
    var x = x0;
    var y = y0;
    var dir = dir0;
    while (true) {
        if (record) visited_cells[y * w + x] = true;
        const key = (y * w + x) * 4 + dir;
        if (seen_states[key] == generation) return true; // loop
        seen_states[key] = generation;
        const dx = [4]i64{ 0, 1, 0, -1 };
        const dy = [4]i64{ -1, 0, 1, 0 };
        const nx = @as(i64, @intCast(x)) + dx[dir];
        const ny = @as(i64, @intCast(y)) + dy[dir];
        if (nx < 0 or ny < 0 or nx >= w or ny >= h) return false; // out
        if (record) {
            base_path.append(gpa, .{ .x = @intCast(x), .y = @intCast(y), .dir = dir, .nx = @intCast(nx), .ny = @intCast(ny) }) catch return false;
        }
        if (grid[@intCast(ny)][@intCast(nx)] == '#') {
            dir = (dir + 1) % 4;
            continue;
        }
        x = @intCast(nx);
        y = @intCast(ny);
    }
}

pub fn main() !void {
    var sx: usize = 0;
    var sy: usize = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        for (line, 0..) |c, x| {
            if (c == '^') {
                sx = x;
                sy = h;
            }
        }
        w = @max(w, line.len);
        h += 1;
    }

    const ncells = w * h;
    defer base_path.deinit(gpa);
    seen_states = try gpa.alloc(u32, ncells * 4);
    defer gpa.free(seen_states);
    visited_cells = try gpa.alloc(bool, ncells);
    defer gpa.free(visited_cells);

    // part 1: record the unobstructed route
    generation = 1;
    @memset(visited_cells, false);
    _ = walk(sx, sy, 0, true);
    var count: u64 = 0;
    for (visited_cells) |v| {
        if (v) count += 1;
    }
    print("part 1: {d}\n", .{count});

    // part 2: for each visited cell, resume the walk from the first base-path
    // step that would move INTO that cell (the walks share the prefix before
    // that point, so only the divergent tail needs simulating).
    var loops: u32 = 0;
    for (visited_cells, 0..) |vis, ci| {
        if (!vis) continue;
        const ox = ci % w;
        const oy = ci / w;
        if (ox == sx and oy == sy) continue;
        // find the first divergence step
        var diverge: ?usize = null;
        for (base_path.items, 0..) |st, i| {
            if (st.nx == ox and st.ny == oy) {
                diverge = i;
                break;
            }
        }
        if (diverge == null) continue;
        const d = base_path.items[diverge.?];
        grid[oy][ox] = '#';
        generation += 1;
        // start AT the divergence state (facing the obstruction)
        if (walk(d.x, d.y, d.dir, false)) {
            loops += 1;
        }
        grid[oy][ox] = '.';
    }
    print("part 2: {d}\n", .{loops});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
