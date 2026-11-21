const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day19.txt");

const Res = [4]i64; // ore, clay, obsidian, geode

const Blueprint = struct {
    id: usize,
    costs: [4]Res, // robot -> cost
    max_ore: i64,
};

fn geodesMax(bp: *const Blueprint, time: i32) i64 {
    // DFS over (time, robots, inventory)
    var best: i64 = 0;
    const State = struct {
        t: i32,
        robots: Res,
        inv: Res,
    };
    var stack: List(State) = .empty;
    defer stack.deinit(gpa);
    stack.append(gpa, .{ .t = time, .robots = .{ 1, 0, 0, 0 }, .inv = .{ 0, 0, 0, 0 } }) catch return 0;

    while (stack.pop()) |st| {
        const optimistic = st.inv[3] + @as(i64, st.t) * st.robots[3] + @divTrunc(@as(i64, st.t) * (st.t - 1), 2);
        if (optimistic <= best) continue;

        if (st.t == 0) {
            if (st.inv[3] > best) best = st.inv[3];
            continue;
        }
        if (st.inv[3] + @as(i64, st.t) * st.robots[3] > best) {
            best = @max(best, st.inv[3]); // let the loop keep going deeper
        }

        // try building each robot (or none)
        build: for (0..4) |r| {
            const ri: i32 = @intCast(3 - r); // prefer geode robots first
            const rb = 3 - r; // robot index 3..0
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
            _ = ri;
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
            stack.append(gpa, .{ .t = t_after, .robots = new_robots, .inv = new_inv }) catch return 0;
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
        };
        try bps.append(gpa, bp);
    }
    for (bps.items) |*bp| {
        bp.max_ore = @max(@max(bp.costs[0][0], bp.costs[1][0]), @max(bp.costs[2][0], bp.costs[3][0]));
    }

    // part 1: 24 minutes, sum id * geodes
    {
        var total: i64 = 0;
        for (bps.items) |*bp| {
            const g = geodesMax(bp, 24);
            total += @as(i64, @intCast(bp.id)) * g;
        }
        print("part 1: {d}\n", .{total});
    }

    // part 2: first 3 blueprints, 32 minutes, product
    {
        var product: i64 = 1;
        for (bps.items[0..@min(3, bps.items.len)]) |*bp| {
            product *= geodesMax(bp, 32);
        }
        print("part 2: {d}\n", .{product});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
