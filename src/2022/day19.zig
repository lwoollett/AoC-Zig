const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day19.txt");

const Res = [4]i64; // ore, clay, obsidian, geode

const Blueprint = struct {
    id: usize,
    costs: [4]Res, // robot -> cost
    max_ore: i64,
    max_clay: i64,
    max_obs: i64,
};

fn geodesMax(bp: *const Blueprint, time: i32) i64 {
    // DFS over (time, robots, inventory); fixed stack (depth <= time,
    // branching <= 4) so the search is allocation-free and thread-safe
    var best: i64 = 0;
    const State = struct {
        t: i32,
        robots: Res,
        inv: Res,
    };
    var stack: [160]State = undefined;
    var sp: usize = 0;
    stack[sp] = .{ .t = time, .robots = .{ 1, 0, 0, 0 }, .inv = .{ 0, 0, 0, 0 } };
    sp += 1;

    while (sp > 0) {
        sp -= 1;
        const st = stack[sp];
        const optimistic = st.inv[3] + @as(i64, st.t) * st.robots[3] + @divTrunc(@as(i64, st.t) * (st.t - 1), 2);
        if (optimistic <= best) continue;

        if (st.t == 0) {
            if (st.inv[3] > best) best = st.inv[3];
            continue;
        }
        if (st.inv[3] + @as(i64, st.t) * st.robots[3] > best) {
            best = @max(best, st.inv[3]); // let the loop keep going deeper
        }

        // try building each robot (geode first)
        var geode_affordable = false;
        {
            const c = bp.costs[3];
            geode_affordable = st.inv[0] >= c[0] and st.inv[2] >= c[2];
        }
        build: for (0..4) |r| {
            const rb = r; // robot index 0..3; pushed last=geode so pop explores geode first
            // cap non-geode robots at the most we could ever spend per minute
            if (rb == 0 and st.robots[0] >= bp.max_ore) continue :build;
            if (rb == 1 and st.robots[1] >= bp.max_clay) continue :build;
            if (rb == 2 and st.robots[2] >= bp.max_obs) continue :build;
            // if a geode robot is affordable now, building it dominates
            if (geode_affordable and rb != 3) continue :build;
            // can we afford it (now or soon)? simulate waiting until affordable
            var needed: Res = undefined;
            var feasible = true;
            for (0..4) |m| {
                const cost = bp.costs[rb][m];
                if (cost == 0) {
                    needed[m] = 0;
                    continue;
                }
                if (st.robots[m] == 0) {
                    feasible = false;
                    break;
                }
                const have = st.inv[m];
                const deficit = cost - have;
                if (deficit <= 0) {
                    needed[m] = 0;
                } else {
                    const w = @divTrunc(deficit + st.robots[m] - 1, st.robots[m]);
                    needed[m] = w;
                }
            }
            if (!feasible) continue :build;
            var max_wait: i64 = 0;
            for (needed) |w| max_wait = @max(max_wait, w);
            // build happens after max_wait minutes; +1 minute to produce with it
            const t_after = st.t - @as(i32, @intCast(max_wait)) - 1;
            if (t_after < 0) continue :build;

            var new_inv: Res = undefined;
            for (0..4) |m| {
                new_inv[m] = st.inv[m] + @as(i64, st.t - t_after) * st.robots[m] - bp.costs[rb][m];
            }
            var new_robots = st.robots;
            new_robots[rb] += 1;
            if (sp < stack.len) {
                stack[sp] = .{ .t = t_after, .robots = new_robots, .inv = new_inv };
                sp += 1;
            }
        }
        // also consider doing nothing for the rest
        {
            const final = st.inv[3] + @as(i64, st.t) * st.robots[3];
            if (final > best) best = final;
        }
    }
    return best;
}

pub fn main() !void {
    var bps: List(Blueprint) = .empty;
    defer bps.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var nums: List(i64) = .empty;
        defer nums.deinit(gpa);
        var it = tokenizeAny(u8, line, "Blueprint :Eachorbotcostsandrobomakesoneclaygeodobsidianrequires");
        while (it.next()) |tok| {
            const v = parseInt(i64, tok, 10) catch continue;
            try nums.append(gpa, v);
        }
        if (nums.items.len < 7) continue;
        const bp = Blueprint{
            .id = @intCast(nums.items[0]),
            .costs = .{
                .{ nums.items[1], 0, 0, 0 },
                .{ nums.items[2], 0, 0, 0 },
                .{ nums.items[3], nums.items[4], 0, 0 },
                .{ nums.items[5], 0, nums.items[6], 0 }, // geode: ore + OBSIDIAN
            },
            .max_ore = 0,
            .max_clay = 0,
            .max_obs = 0,
        };
        try bps.append(gpa, bp);
    }
    for (bps.items) |*bp| {
        bp.max_ore = @max(@max(bp.costs[0][0], bp.costs[1][0]), @max(bp.costs[2][0], bp.costs[3][0]));
        bp.max_clay = bp.costs[2][1];
        bp.max_obs = bp.costs[3][2];
    }

    // part 1: 24 minutes, sum id * geodes (blueprints in parallel)
    {
        var results = std.mem.zeroes([64]i64);
        var next = std.atomic.Value(usize).init(0);
        const Worker = struct {
            fn run(blueprints: []Blueprint, res: *[64]i64, nx: *std.atomic.Value(usize)) void {
                while (true) {
                    const i = nx.fetchAdd(1, .monotonic);
                    if (i >= blueprints.len) break;
                    res[i] = geodesMax(&blueprints[i], 24);
                }
            }
        };
        const nthreads = @min(bps.items.len, std.Thread.getCpuCount() catch 1);
        var threads: [64]std.Thread = undefined;
        for (0..nthreads) |k| {
            threads[k] = try std.Thread.spawn(.{}, Worker.run, .{ bps.items, &results, &next });
        }
        var total: i64 = 0;
        for (0..nthreads) |k| threads[k].join();
        for (bps.items, 0..) |*bp, i| {
            total += @as(i64, @intCast(bp.id)) * results[i];
        }
        print("part 1: {d}\n", .{total});
    }

    // part 2: first 3 blueprints, 32 minutes, product (in parallel)
    {
        const m = @min(3, bps.items.len);
        var results = std.mem.zeroes([64]i64);
        var next = std.atomic.Value(usize).init(0);
        const Worker = struct {
            fn run(blueprints: []Blueprint, res: *[64]i64, nx: *std.atomic.Value(usize)) void {
                while (true) {
                    const i = nx.fetchAdd(1, .monotonic);
                    if (i >= 3) break;
                    res[i] = geodesMax(&blueprints[i], 32);
                }
            }
        };
        const nthreads = @min(m, std.Thread.getCpuCount() catch 1);
        var threads: [64]std.Thread = undefined;
        for (0..nthreads) |k| {
            threads[k] = try std.Thread.spawn(.{}, Worker.run, .{ bps.items, &results, &next });
        }
        var product: i64 = 1;
        for (0..nthreads) |k| threads[k].join();
        for (0..m) |i| product *= results[i];
        print("part 2: {d}\n", .{product});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
