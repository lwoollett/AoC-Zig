const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day12.txt");

const max_w = 50;

const Orient = struct {
    w: u8,
    h: u8,
    rows: [3]u64, // bitmasks, LSB = leftmost column
};

/// all distinct orientations (rotations + reflections) of one shape
var orients: [6]List(Orient) = @splat(.empty);

fn genOrients(shape_idx: usize, base: []const []const u8) !void {
    var cur = base;
    var seen: List([3]u64) = .empty;
    defer seen.deinit(gpa);
    var rep: u8 = 0;
    while (rep < 2) : (rep += 1) {
        var rot: u8 = 0;
        while (rot < 4) : (rot += 1) {
            // build bitmask rows for cur
            const hh = cur.len;
            var ww: usize = 0;
            for (cur) |row| {
                ww = @max(ww, row.len);
            }
            var rows: [3]u64 = .{ 0, 0, 0 };
            for (cur, 0..) |row, y| {
                for (row, 0..) |c, x| {
                    if (c == '#') {
                        rows[y] |= @as(u64, 1) << @intCast(x);
                    }
                }
            }
            // dedup
            var dup = false;
            for (seen.items) |s| {
                if (s[0] == rows[0] and s[1] == rows[1] and s[2] == rows[2]) dup = true;
            }
            if (!dup) {
                try seen.append(gpa, rows);
                try orients[shape_idx].append(gpa, .{ .w = @intCast(ww), .h = @intCast(hh), .rows = rows });
            }
            // rotate 90° clockwise: new[y][x] = old[h-1-x][y]
            var next: List([]u8) = .empty;
            defer next.deinit(gpa);
            var ny: usize = 0;
            while (ny < ww) : (ny += 1) {
                const row = try gpa.alloc(u8, hh);
                defer gpa.free(row);
                var nx: usize = 0;
                while (nx < hh) : (nx += 1) {
                    // new[ny][nx] = cur[hh-1-nx][ny]
                    const src_row = cur[hh - 1 - nx];
                    row[nx] = if (ny < src_row.len) src_row[ny] else '.';
                }
                try next.append(gpa, row);
            }
            // store rotated rows persistently
            const persist = try gpa.alloc([]u8, next.items.len);
            for (next.items, 0..) |r, i| {
                persist[i] = try gpa.dupe(u8, r);
            }
            cur = persist;
        }
        // reflect horizontally for the second rep
        const refl = try gpa.alloc([]u8, cur.len);
        for (cur, 0..) |r, i| {
            const row = try gpa.alloc(u8, r.len);
            for (r, 0..) |c, x| {
                row[r.len - 1 - x] = c;
            }
            refl[i] = row;
        }
        cur = refl;
    }
}

const Grid = struct {
    w: u8,
    h: u8,
    rows: [50]u64,
};

var remaining: [6]u32 = @splat(0);
var grid: Grid = undefined;
var nodes: u64 = 0;
var need_total: u64 = 0;

/// count free cells
fn freeCells() u64 {
    var free: u64 = 0;
    const mask = (@as(u64, 1) << @intCast(grid.w)) - 1;
    for (0..grid.h) |y| {
        free += @popCount(~grid.rows[y] & mask);
    }
    return free;
}

/// branch on the first undecided cell (row-major): leave empty or cover it
fn solvePack(cell: usize) bool {
    nodes += 1;
    if (nodes > 200_000_000) return false; // search cap
    // skip filled cells
    var i = cell;
    while (i < @as(usize, grid.w) * grid.h) : (i += 1) {
        const y = i / grid.w;
        const x = i % grid.w;
        if ((grid.rows[y] >> @intCast(x)) & 1 == 0) break;
    }
    if (i >= @as(usize, grid.w) * grid.h) {
        // no empty cell left to decide: done when all pieces placed
        for (0..6) |s| {
            if (remaining[s] != 0) return false;
        }
        return true;
    }
    // prune: not enough free cells for the remaining pieces
    var need: u64 = 0;
    for (0..6) |s| {
        if (remaining[s] == 0) continue;
        var cells: u64 = 0;
        for (orients[s].items[0].rows) |r| {
            cells += @popCount(r);
        }
        need += cells * remaining[s];
    }
    if (freeCells() < need) return false;

    const fy = i / grid.w;
    const fx = i % grid.w;

    // option (b): cover cell i with a piece (try every shape/orientation
    // whose '#' can sit on (fx, fy))
    for (0..6) |s| {
        if (remaining[s] == 0) continue;
        for (orients[s].items) |o| {
            for (0..o.h) |dr| {
                for (0..o.w) |dc| {
                    if ((o.rows[dr] >> @intCast(dc)) & 1 == 0) continue;
                    if (fx < dc or fy < dr) continue;
                    const px = fx - dc;
                    const py = fy - dr;
                    if (px + o.w > grid.w or py + o.h > grid.h) continue;
                    var ok = true;
                    for (0..o.h) |k| {
                        if (grid.rows[py + k] & (o.rows[k] << @intCast(px)) != 0) {
                            ok = false;
                            break;
                        }
                    }
                    if (!ok) continue;
                    for (0..o.h) |k| {
                        grid.rows[py + k] |= o.rows[k] << @intCast(px);
                    }
                    remaining[s] -= 1;
                    if (solvePack(i + 1)) return true;
                    remaining[s] += 1;
                    for (0..o.h) |k| {
                        grid.rows[py + k] &= ~(o.rows[k] << @intCast(px));
                    }
                }
            }
        }
    }
    // option (a): leave cell i empty
    return solvePack(i + 1);
}

pub fn main() !void {
    // parse shapes then regions
    var lines = splitSca(u8, data, '\n');
    var shape_rows: List([]const u8) = .empty;
    defer shape_rows.deinit(gpa);
    var shape_idx: usize = 0;
    var in_regions = false;
    var feasible: u32 = 0;
    var solved_count: u32 = 0;

    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) continue;
        if (line[0] >= '0' and line[0] <= '9' and indexOf(u8, line, 'x') != null) {
            in_regions = true;
        }
        if (!in_regions) {
            if (line[line.len - 1] == ':') {
                shape_idx = try parseInt(usize, line[0 .. line.len - 1], 10);
                shape_rows.clearRetainingCapacity();
                continue;
            }
            try shape_rows.append(gpa, line);
            // shapes are 3 rows; when we have 3 rows the shape is complete
            if (shape_rows.items.len == 3) {
                try genOrients(shape_idx, shape_rows.items);
                shape_rows.clearRetainingCapacity();
            }
            continue;
        }
        // region: "45x41: 52 43 45 41 47 59"
        const x_at = indexOf(u8, line, 'x').?;
        const colon = indexOf(u8, line, ':').?;
        const w = try parseInt(u8, line[0..x_at], 10);
        const h = try parseInt(u8, line[x_at + 1 .. colon], 10);
        var it = tokenizeSca(u8, line[colon + 1 ..], ' ');
        var i: usize = 0;
        while (it.next()) |tok| : (i += 1) {
            remaining[i] = try parseInt(u32, tok, 10);
        }
        var need: u64 = 0;
        for (0..6) |s| {
            var cells: u64 = 0;
            for (orients[s].items[0].rows) |r| {
                cells += @popCount(r);
            }
            need += cells * remaining[s];
        }
        if (need > @as(u64, w) * h) continue;
        feasible += 1;
        // pack
        grid = .{ .w = w, .h = h, .rows = @splat(0) };
        nodes = 0;
        if (solvePack(0)) {
            solved_count += 1;
        }
    }
    print("part 1: {d}\n", .{solved_count});
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
// Only unmodified days will be modified.
