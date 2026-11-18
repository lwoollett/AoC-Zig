const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day22.txt");

const Box = struct { x0: i64, x1: i64, y0: i64, y1: i64, z0: i64, z1: i64 };

fn volume(b: Box) i128 {
    const dx: i128 = @intCast(b.x1 - b.x0 + 1);
    const dy: i128 = @intCast(b.y1 - b.y0 + 1);
    const dz: i128 = @intCast(b.z1 - b.z0 + 1);
    return dx * dy * dz;
}

fn intersect(a: Box, b: Box) ?Box {
    const x0 = @max(a.x0, b.x0);
    const x1 = @min(a.x1, b.x1);
    const y0 = @max(a.y0, b.y0);
    const y1 = @min(a.y1, b.y1);
    const z0 = @max(a.z0, b.z0);
    const z1 = @min(a.z1, b.z1);
    if (x0 > x1 or y0 > y1 or z0 > z1) return null;
    return .{ .x0 = x0, .x1 = x1, .y0 = y0, .y1 = y1, .z0 = z0, .z1 = z1 };
}

/// Remove c from every box in the list (splitting as needed).
fn subtractFrom(list: *List(Box), c: Box) !void {
    var out: List(Box) = .empty;
    for (list.items) |b| {
        const inter = intersect(b, c) orelse {
            try out.append(gpa, b);
            continue;
        };
        // slice b into up to 6 pieces excluding inter
        var rest = b;
        // x slabs
        if (rest.x0 < inter.x0) {
            try out.append(gpa, .{ .x0 = rest.x0, .x1 = inter.x0 - 1, .y0 = rest.y0, .y1 = rest.y1, .z0 = rest.z0, .z1 = rest.z1 });
        }
        if (rest.x1 > inter.x1) {
            try out.append(gpa, .{ .x0 = inter.x1 + 1, .x1 = rest.x1, .y0 = rest.y0, .y1 = rest.y1, .z0 = rest.z0, .z1 = rest.z1 });
        }
        rest.x0 = inter.x0;
        rest.x1 = inter.x1;
        // y slabs
        if (rest.y0 < inter.y0) {
            try out.append(gpa, .{ .x0 = rest.x0, .x1 = rest.x1, .y0 = rest.y0, .y1 = inter.y0 - 1, .z0 = rest.z0, .z1 = rest.z1 });
        }
        if (rest.y1 > inter.y1) {
            try out.append(gpa, .{ .x0 = rest.x0, .x1 = rest.x1, .y0 = inter.y1 + 1, .y1 = rest.y1, .z0 = rest.z0, .z1 = rest.z1 });
        }
        rest.y0 = inter.y0;
        rest.y1 = inter.y1;
        // z slabs
        if (rest.z0 < inter.z0) {
            try out.append(gpa, .{ .x0 = rest.x0, .x1 = rest.x1, .y0 = rest.y0, .y1 = rest.y1, .z0 = rest.z0, .z1 = inter.z0 - 1 });
        }
        if (rest.z1 > inter.z1) {
            try out.append(gpa, .{ .x0 = rest.x0, .x1 = rest.x1, .y0 = rest.y0, .y1 = rest.y1, .z0 = inter.z1 + 1, .z1 = rest.z1 });
        }
        // the remaining core is the intersection — dropped
    }
    list.deinit(gpa);
    list.* = out;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");

    // part 1: bounded grid
    var grid = try gpa.alloc(u8, 101 * 101 * 101);
    defer gpa.free(grid);
    @memset(grid, 0);

    var boxes: List(Box) = .empty;
    defer boxes.deinit(gpa);

    while (lines.next()) |line| {
        const on = std.mem.startsWith(u8, line, "on");
        const x_at = std.mem.indexOf(u8, line, "x=").?;
        const y_at = std.mem.indexOf(u8, line, "y=").?;
        const z_at = std.mem.indexOf(u8, line, "z=").?;
        const parseRange = struct {
            fn f(s: []const u8) !struct { lo: i64, hi: i64 } {
                const dots = std.mem.indexOf(u8, s, "..").?;
                return .{ .lo = try parseInt(i64, s[0..dots], 10), .hi = try parseInt(i64, s[dots + 2 ..], 10) };
            }
        }.f;
        const xr = try parseRange(line[x_at + 2 .. y_at - 1]);
        const yr = try parseRange(line[y_at + 2 .. z_at - 1]);
        const zr = try parseRange(line[z_at + 2 ..]);

        // part 1 (bounded)
        if (xr.lo >= -50 and xr.hi <= 50 and yr.lo >= -50 and yr.hi <= 50 and zr.lo >= -50 and zr.hi <= 50) {
            var x = @max(xr.lo, -50);
            while (x <= @min(xr.hi, 50)) : (x += 1) {
                var y = @max(yr.lo, -50);
                while (y <= @min(yr.hi, 50)) : (y += 1) {
                    var z = @max(zr.lo, -50);
                    while (z <= @min(zr.hi, 50)) : (z += 1) {
                        const idx = (@as(usize, @intCast(x + 50))) * 101 * 101 +
                            (@as(usize, @intCast(y + 50))) * 101 +
                            (@as(usize, @intCast(z + 50)));
                        grid[idx] = @intFromBool(on);
                    }
                }
            }
        }

        // part 2 (cuboid list)
        const c = Box{ .x0 = xr.lo, .x1 = xr.hi, .y0 = yr.lo, .y1 = yr.hi, .z0 = zr.lo, .z1 = zr.hi };
        try subtractFrom(&boxes, c);
        if (on) {
            try boxes.append(gpa, c);
        }
    }

    var p1: usize = 0;
    for (grid) |v| {
        if (v == 1) p1 += 1;
    }
    print("part 1: {d}\n", .{p1});

    var p2: i128 = 0;
    for (boxes.items) |b| {
        p2 += volume(b);
    }
    print("part 2: {d}\n", .{p2});
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
