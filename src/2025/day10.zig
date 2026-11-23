const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

const data = @embedFile("data/day10.txt");

// ---------------------------------------------------------------------------
// shared machine parsing: buttons as counter-bitmask lists + numeric targets
// ---------------------------------------------------------------------------

const Machine = struct {
    buttons: []u32, // bitmask over counters
    targets: []i64,

    fn parse(line: []const u8, btns_buf: *List(u32), tgt_buf: *List(i64)) !Machine {
        const brace = indexOf(u8, line, '{').?;
        {
            var it = tokenizeAny(u8, line[brace + 1 .. line.len - 1], ",");
            while (it.next()) |tok| {
                try tgt_buf.append(gpa, try parseInt(i64, tok, 10));
            }
        }
        var idx = indexOf(u8, line, '(').?;
        while (true) {
            const close = std.mem.indexOfScalarPos(u8, line, idx, ')').?;
            var mask: u32 = 0;
            var it = tokenizeAny(u8, line[idx + 1 .. close], ",");
            while (it.next()) |tok| {
                const bit = try parseInt(u5, tok, 10);
                mask |= @as(u32, 1) << bit;
            }
            try btns_buf.append(gpa, mask);
            const next = std.mem.indexOfScalarPos(u8, line, close + 1, '(');
            idx = next orelse break;
        }
        return .{ .buttons = btns_buf.items, .targets = tgt_buf.items };
    }
};

// ---------------------------------------------------------------------------
// part 1: indicator lights — toggle-to-target via subset enumeration
// ---------------------------------------------------------------------------

pub fn main() !void {
    var total: u64 = 0;
    var total2: u64 = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const bracket_end = indexOf(u8, line, ']').?;
        var target: u32 = 0;
        for (line[1..bracket_end], 0..) |c, i| {
            if (c == '#') target |= @as(u32, 1) << @intCast(i);
        }

        var buttons: List(u32) = .empty;
        defer buttons.deinit(gpa);
        var targets: List(i64) = .empty;
        defer targets.deinit(gpa);
        const m = try Machine.parse(line, &buttons, &targets);

        // part 1: XOR subset search
        {
            const nb = m.buttons.len;
            var best: u32 = std.math.maxInt(u32);
            var subset: u64 = 0;
            while (subset < (@as(u64, 1) << @intCast(nb))) : (subset += 1) {
                var acc: u32 = 0;
                var presses: u32 = 0;
                for (m.buttons, 0..) |b, bi| {
                    if ((subset >> @intCast(bi)) & 1 == 1) {
                        acc ^= b;
                        presses += 1;
                    }
                }
                if (acc == target and presses < best) {
                    best = presses;
                }
            }
            total += best;
        }

        // part 2: exact-hit ILP via LP-bound branch and bound
        total2 += try minPresses(m.buttons, m.targets);
    }
    print("part 1: {d}\n", .{total});
    print("part 2: {d}\n", .{total2});
}

// ---------------------------------------------------------------------------
// part 2: min sum(x) s.t. for each counter c: sum_{b covers c} x_b == t_c,
// x >= 0 integer. Node bound = LP relaxation via two-phase simplex (Bland).
// ---------------------------------------------------------------------------

const MAXR = 10; // counters
const MAXV = 16; // variables (buttons)
const TBW = MAXV + MAXR + 1; // tableau width: vars + artificials + rhs
const TBH = MAXR + 1; // constraint rows + cost row

var tb: [TBH][TBW]f64 = undefined;
var basis: [MAXR]usize = undefined;

/// min sum x s.t. Ax = r, x >= 0 over `nv` buttons. Returns the LP optimum,
/// or +inf if infeasible.
fn lpBound(nv: usize, rows: usize, r: []const i64) f64 {
    const W = nv + rows + 1;
    for (0..TBH) |i| @memset(&tb[i], 0);
    for (0..rows) |i| {
        for (0..nv) |j| {
            if ((curButtons[curOrder[curOff + j]] >> @intCast(i)) & 1 == 1) tb[i][j] = 1;
        }
        tb[i][nv + i] = 1;
        tb[i][W - 1] = @floatFromInt(r[i]);
        basis[i] = nv + i;
    }
    // phase 1: minimize sum of artificials. Reduced costs: real var j is
    // c_j - sum_i a_ij = -sum_i a_ij; artificials are basic with cost 1 and
    // reduced cost 0.
    {
        for (0..nv) |j| tb[rows][j] = 0;
        for (0..rows) |i| {
            for (0..nv) |j| tb[rows][j] -= tb[i][j];
        }
        for (0..rows) |i| tb[rows][nv + i] = 0;
        tb[rows][W - 1] = 0;
    }
    simplexRun(rows, W, rows, nv + rows);
    // phase-1 objective: value of artificials still basic
    var p1: f64 = 0;
    for (0..rows) |i| {
        if (basis[i] >= nv) p1 += @max(0, tb[i][W - 1]);
    }
    if (p1 > 1e-7) return std.math.inf(f64);
    // drive artificials out of the basis (a degenerate artificial row must
    // not survive into phase 2 — a later pivot can make it positive and
    // silently violate its constraint)
    {
        var i: usize = 0;
        while (i < rows) : (i += 1) {
            if (basis[i] >= nv) {
                for (0..nv) |j| {
                    if (@abs(tb[i][j]) > 1e-9) {
                        // pivot (i, j): row i's rhs is 0, so other rows' rhs
                        // are unchanged
                        const piv = tb[i][j];
                        for (0..W) |k| tb[i][k] /= piv;
                        for (0..rows) |k| {
                            if (k == i) continue;
                            const f = tb[k][j];
                            if (@abs(f) > 1e-12) {
                                for (0..W) |c| tb[k][c] -= f * tb[i][c];
                            }
                        }
                        basis[i] = j;
                        break;
                    }
                }
            }
        }
    }
    // phase 2: min sum of real vars
    for (0..W) |j| tb[rows][j] = 0;
    for (0..nv) |j| tb[rows][j] = 1;
    for (0..rows) |i| {
        if (basis[i] < nv) {
            const c = tb[rows][basis[i]];
            if (c != 0) {
                for (0..W) |j| tb[rows][j] -= c * tb[i][j];
            }
        }
    }
    simplexRun(rows, W, rows, nv);
    var obj: f64 = 0;
    @memset(&lpX, 0);
    for (0..rows) |i| {
        if (basis[i] < nv) {
            obj += tb[i][W - 1];
            lpX[basis[i]] = tb[i][W - 1];
        }
    }
    return obj;
}

var lpX: [MAXV]f64 = undefined;

fn simplexRun(m: usize, W: usize, crow: usize, ncols: usize) void {
    var guard: usize = 0;
    while (guard < 10000) : (guard += 1) {
        var enter: ?usize = null;
        for (0..ncols) |j| {
            if (tb[crow][j] < -1e-9) {
                enter = j;
                break; // Bland: first improving column
            }
        }
        if (enter == null) return;
        const e = enter.?;
        var leave: ?usize = null;
        var best_ratio: f64 = std.math.inf(f64);
        for (0..m) |i| {
            if (tb[i][e] > 1e-9) {
                const ratio = tb[i][W - 1] / tb[i][e];
                if (ratio < best_ratio - 1e-10 or
                    (ratio < best_ratio + 1e-10 and leave != null and basis[i] < basis[leave.?]))
                {
                    best_ratio = ratio;
                    leave = i;
                }
            }
        }
        if (leave == null) return; // unbounded — cannot happen here
        const l = leave.?;
        const piv = tb[l][e];
        if (piv != 1) {
            for (0..W) |j| tb[l][j] /= piv;
        }
        for (0..m + 1) |i| {
            if (i == l) continue;
            const f = tb[i][e];
            if (@abs(f) > 1e-12) {
                for (0..W) |j| tb[i][j] -= f * tb[l][j];
            }
        }
        basis[l] = e;
    }
}

var curButtons: []u32 = &.{};
var curOrder: []const usize = &.{};
var curOff: usize = 0;

/// integer search: iterative deepening on total presses, each node pruned
/// by the LP relaxation of the residual system
var bbTarget: u64 = 0;
var bbFound: bool = false;
var bbOrder: [MAXV]usize = undefined;

fn bbDFS(nv: usize, rows: usize, order: []const usize, oi: usize, rem: []i64, used: u64) void {
    if (used > bbTarget) return;
    var all_zero = true;
    for (rem[0..rows]) |v| {
        if (v < 0) return;
        if (v != 0) all_zero = false;
    }
    if (all_zero) {
        bbFound = true;
        return;
    }
    if (oi >= order.len) return;
    curOff = oi;
    const bound = lpBound(nv - oi, rows, rem[0..rows]);
    if (std.math.isInf(bound)) return;
    const used_bound = used + @as(u64, @intFromFloat(@max(0, @ceil(bound - 1e-9))));
    if (used_bound > bbTarget) return;
    const b = curButtons[order[oi]];
    var k: i64 = std.math.maxInt(i64);
    for (0..rows) |c| {
        if ((b >> @intCast(c)) & 1 == 1 and rem[c] < k) k = rem[c];
    }
    var times: i64 = @min(k, @as(i64, @intCast(bbTarget - used)));
    while (times >= 0) : (times -= 1) {
        var nr: [MAXR]i64 = @splat(0);
        for (rem[0..rows], 0..) |v, c| nr[c] = v;
        var ok = true;
        for (0..rows) |c| {
            if ((b >> @intCast(c)) & 1 == 1) {
                nr[c] -= times;
                if (nr[c] < 0) ok = false;
            }
        }
        if (ok) bbDFS(nv, rows, order, oi + 1, &nr, used + @as(u64, @intCast(times)));
        if (bbFound) return;
        if (times == 0) break;
    }
}

fn minPresses(buttons: []u32, targets: []i64) !u64 {
    curButtons = buttons;
    const rows = targets.len;
    const nv = buttons.len;
    // order buttons by popcount desc (big first)
    for (0..nv) |i| bbOrder[i] = i;
    std.mem.sort(usize, bbOrder[0..nv], buttons, struct {
        fn lessThan(bs: []u32, a: usize, b: usize) bool {
            return @popCount(bs[a]) > @popCount(bs[b]);
        }
    }.lessThan);
    curOrder = bbOrder[0..nv];
    curOff = 0;
    const lp = lpBound(nv, rows, targets);
    if (std.math.isInf(lp)) return error.Infeasible;
    // an integral LP *solution vector* is integer-optimal (a feasible
    // integer point matching the lower bound)
    var integral = true;
    for (0..nv) |j| {
        if (@abs(lpX[j] - @round(lpX[j])) > 1e-7) integral = false;
    }
    if (integral) {
        var s: u64 = 0;
        for (0..nv) |j| s += @intFromFloat(@round(lpX[j]));
        return s;
    }
    var rem: [MAXR]i64 = @splat(0);
    for (targets, 0..) |t, c| rem[c] = t;
    // iterative deepening from the LP lower bound
    var p: u64 = @intFromFloat(@ceil(lp - 1e-9));
    while (p < 100000) : (p += 1) {
        bbTarget = p;
        bbFound = false;
        bbDFS(nv, rows, bbOrder[0..nv], 0, &rem, 0);
        if (bbFound) return p;
    }
    return error.Infeasible;
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
