const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


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

    // part 2: solve for the rock (Px,Py,Pz,Vx,Vy,Vz) via cross-product
    // elimination rows from several hailstone pairs (any 2 pairs give 6
    // equations, but a pair can be degenerate — collect rows from pairs
    // (0,k) for several k and pivot greedily across all of them).
    {
        var rows: List([7]f128) = .empty;
        defer rows.deinit(gpa);
        const h0 = hails.items[0];
        for (1..@min(6, hails.items.len)) |k| {
            const hk = hails.items[k];
            // master equation per component:
            //   P x (v0 - vk) + (p0 - pk) x V = (p0 x v0) - (pk x vk)
            // rows [X, Y, Z, A, B, C | rhs] derived by direct evaluation
            var xeq: [7]f128 = .{ 0, h0.vz - hk.vz, hk.vy - h0.vy, 0, hk.pz - h0.pz, h0.py - hk.py, 0 };
            xeq[6] = (h0.py * h0.vz - h0.pz * h0.vy) - (hk.py * hk.vz - hk.pz * hk.vy);
            try rows.append(gpa, xeq);
            var yeq: [7]f128 = .{ hk.vz - h0.vz, 0, h0.vx - hk.vx, h0.pz - hk.pz, 0, hk.px - h0.px, 0 };
            yeq[6] = (h0.pz * h0.vx - h0.px * h0.vz) - (hk.pz * hk.vx - hk.px * hk.vz);
            try rows.append(gpa, yeq);
            var zeq: [7]f128 = .{ h0.vy - hk.vy, hk.vx - h0.vx, 0, hk.py - h0.py, h0.px - hk.px, 0, 0 };
            zeq[6] = (h0.px * h0.vy - h0.py * h0.vx) - (hk.px * hk.vy - hk.py * hk.vx);
            try rows.append(gpa, zeq);
        }

        // Gaussian elimination with row selection across all candidate rows
        const nrows = rows.items.len;
        var used: [64]bool = @splat(false);
        var sol: [6]f128 = @splat(0);
        var piv_rows: [6]usize = @splat(0);
        for (0..6) |col| {
            var best: usize = nrows;
            var best_abs: f128 = 0;
            for (0..nrows) |r| {
                if (used[r]) continue;
                const a = @abs(rows.items[r][col]);
                if (a > best_abs) {
                    best_abs = a;
                    best = r;
                }
            }
            if (best == nrows or best_abs < 1e-9) {
                print("part 2: degenerate system (col {d})\n", .{col});
                return error.Degenerate;
            }
            used[best] = true;
            piv_rows[col] = best;
            const d = rows.items[best][col];
            for (col..7) |j| rows.items[best][j] /= d;
            for (0..nrows) |r| {
                if (r == best) continue;
                const f = rows.items[r][col];
                if (f == 0) continue;
                for (col..7) |j| rows.items[r][j] -= f * rows.items[best][j];
            }
        }
        // back-substitute (each pivot row is normalized in its column)
        for (0..6) |col| {
            sol[col] = rows.items[piv_rows[col]][6];
        }

        const X: f128 = sol[0];
        const Y: f128 = sol[1];
        const Z: f128 = sol[2];

        // validate: every hailstone must be hit at some real time t >= 0
        const Vx: f128 = sol[3];
        const Vy: f128 = sol[4];
        const Vz: f128 = sol[5];
        for (hails.items) |hh| {
            // solve Px + Vx t = px + vx t from x; check y, z
            const denom = Vx - hh.vx;
            if (@abs(denom) < 1e-9) continue;
            const t = (hh.px - X) / denom;
            const y = Y + Vy * t;
            const z = Z + Vz * t;
            if (@abs(y - (hh.py + hh.vy * t)) > 1e-3 or @abs(z - (hh.pz + hh.vz * t)) > 1e-3) {
                print("part 2: solution failed validation\n", .{});
                return error.BadSolution;
            }
        }
        const sum: i128 = @intFromFloat(@round(X + Y + Z));
        print("part 2: {d}\n", .{sum});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseFloat = std.fmt.parseFloat;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
