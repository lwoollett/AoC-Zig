const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day24.txt");

const Hail = struct { px: f128, py: f128, pz: f128, vx: f128, vy: f128, vz: f128 };

const test_lo: f128 = 200000000000000.0;
const test_hi: f128 = 400000000000000.0;

pub fn main() !void {
    var hails: List(Hail) = .empty;
    defer hails.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var nums: [6]f128 = undefined;
        var it = tokenizeAny(u8, line, ", @");
        var i: usize = 0;
        while (it.next()) |tok| : (i += 1) {
            nums[i] = try parseFloat(f128, tok);
        }
        try hails.append(gpa, .{ .px = nums[0], .py = nums[1], .pz = nums[2], .vx = nums[3], .vy = nums[4], .vz = nums[5] });
    }

    // part 1: 2D intersections in the test area
    {
        var count: u64 = 0;
        for (hails.items, 0..) |a, i| {
            for (hails.items[i + 1 ..]) |b| {
                // a.px + t*a.vx = b.px + u*b.vx (x,y only)
                const det = a.vx * b.vy - a.vy * b.vx;
                if (det == 0) continue; // parallel
                const t = ((b.px - a.px) * b.vy - (b.py - a.py) * b.vx) / det;
                const u = ((b.px - a.px) * a.vy - (b.py - a.py) * a.vx) / det;
                if (t < 0 or u < 0) continue;
                const ix = a.px + t * a.vx;
                const iy = a.py + t * a.vy;
                if (ix >= test_lo and ix <= test_hi and iy >= test_lo and iy <= test_hi) {
                    count += 1;
                }
            }
        }
        print("part 1: {d}\n", .{count});
    }

    // part 2: solve for the rock with a 6x6 linear system (f128 Gaussian)
    // unknowns X, Y, Z, A, B, C (rock pos + vel)
    {
        // For each pair (0, k): cross-product elimination gives 3 linear equations:
        //   X*(vy_k - vy_0) - Y*(vx_k - vx_0) + A*(y_0 - y_k) + B*(x_k - x_0) = rhs1
        //   X*(vz_k - vz_0) - Z*(vx_k - vx_0) + A*(z_0 - z_k) + C*(x_k - x_0) = rhs2
        //   Y*(vz_k - vz_0) - Z*(vy_k - vy_0) + B*(z_0 - z_k) + C*(y_k - y_0) = rhs3
        // Use k = 1 and k = 2 to get 6 equations; solve least... just take
        // the 6 equations from two pairs (each pair yields 3).
        var mat: [6][7]f128 = undefined; // augmented
        const h0 = hails.items[0];
        for (0..2) |row_block| {
            const k = row_block + 1;
            const hk = hails.items[k];
            // eq 1: X*(vy_k - vy_0) - Y*(vx_k - vx_0) + A*(y_0 - y_k) + B*(x_k - x_0)
            mat[row_block * 3 + 0] = .{ hk.vy - h0.vy, -(hk.vx - h0.vx), 0, h0.py - hk.py, hk.px - h0.px, 0, 0 };
            mat[row_block * 3 + 0][6] = hk.px * hk.vy - h0.px * h0.vy + h0.py * h0.vx - hk.py * hk.vx;
            // eq 2: X*(vz_k - vz_0) - Z*(vx_k - vx_0) + A*(z_0 - z_k) + C*(x_k - x_0)
            mat[row_block * 3 + 1] = .{ hk.vz - h0.vz, 0, -(hk.vx - h0.vx), h0.pz - hk.pz, 0, hk.px - h0.px, 0 };
            mat[row_block * 3 + 1][6] = hk.px * hk.vz - h0.px * h0.vz + h0.pz * h0.vx - hk.pz * hk.vx;
            // eq 3: Y*(vz_k - vz_0) - Z*(vy_k - vy_0) + B*(z_0 - z_k) + C*(y_k - y_0)
            mat[row_block * 3 + 2] = .{ 0, hk.vz - h0.vz, -(hk.vy - h0.vy), 0, h0.pz - hk.pz, hk.py - h0.py, 0 };
            mat[row_block * 3 + 2][6] = hk.py * hk.vz - h0.py * h0.vz + h0.pz * h0.vy - hk.pz * h0.vy;
        }

        // Gaussian elimination
        for (0..6) |col| {
            // pivot
            var piv = col;
            for (col..6) |r| {
                if (@abs(mat[r][col]) > @abs(mat[piv][col])) piv = r;
            }
            const tmp = mat[col];
            mat[col] = mat[piv];
            mat[piv] = tmp;
            const d = mat[col][col];
            if (d == 0) continue;
            for (col..7) |j| {
                mat[col][j] /= d;
            }
            for (0..6) |r| {
                if (r == col) continue;
                const f = mat[r][col];
                if (f == 0) continue;
                for (col..7) |j| {
                    mat[r][j] -= f * mat[col][j];
                }
            }
        }

        const X: i128 = @intFromFloat(@round(mat[0][6]));
        const Y: i128 = @intFromFloat(@round(mat[1][6]));
        const Z: i128 = @intFromFloat(@round(mat[2][6]));
        print("part 2: {d}\n", .{X + Y + Z});
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
// Only unmodified days will be modified.
