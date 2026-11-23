const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day23.txt");

// Flat u8 occupancy grid instead of hash maps: coordinates stay within
// input extent + rounds (each elf moves <= 1 per round, ~965 rounds here).
const OFF: i32 = 1200;
const GW: usize = 2400;
const GH: usize = 2400;

const all_n = [8][2]i32{
    .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 },
    .{ -1, 0 },  .{ 1, 0 },  .{ -1, 1 },
    .{ 0, 1 },   .{ 1, 1 },
};

const dir_sets = [4][3][2]i32{
    .{ .{ 0, -1 }, .{ -1, -1 }, .{ 1, -1 } }, // N, NE, NW
    .{ .{ 0, 1 }, .{ -1, 1 }, .{ 1, 1 } }, // S, SE, SW
    .{ .{ -1, 0 }, .{ -1, -1 }, .{ -1, 1 } }, // W, NW, SW
    .{ .{ 1, 0 }, .{ 1, -1 }, .{ 1, 1 } }, // E, NE, SE
};

var occ: [GW * GH]u8 = @splat(0);
var counts: [GW * GH]u8 = @splat(0);
var touched: List(u32) = .empty;
var targets: List(i32) = .empty; // per-elf proposed cell index, -1 = none

fn idx(x: i32, y: i32) u32 {
    return @intCast((y + OFF) * @as(i32, GW) + (x + OFF));
}

const Sim = struct {
    xs: List(i32) = .empty,
    ys: List(i32) = .empty,

    fn init() !Sim {
        var s = Sim{};
        var lines = tokenizeAny(u8, data, "\n");
        var row: i32 = 0;
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            const y = row;
            row += 1;
            for (line, 0..) |c, x| {
                if (c == '#') {
                    try s.xs.append(gpa, @intCast(x));
                    try s.ys.append(gpa, y);
                }
            }
        }
        for (s.xs.items, s.ys.items) |x, y| occ[idx(x, y)] = 1;
        return s;
    }

    fn round(s: *Sim, first_dir: u8) bool {
        const n = s.xs.items.len;
        targets.clearRetainingCapacity();
        targets.ensureTotalCapacity(gpa, n) catch return false;
        // reset per-round target counts via the touched list
        for (touched.items) |c| counts[c] = 0;
        touched.clearRetainingCapacity();

        for (s.xs.items, s.ys.items) |x, y| {
            var any = false;
            for (all_n) |nb| {
                if (occ[idx(x + nb[0], y + nb[1])] != 0) any = true;
            }
            if (!any) {
                targets.appendAssumeCapacity(-1);
                continue;
            }
            var proposed: i32 = -1;
            for (0..4) |k| {
                const d = (first_dir + @as(u8, @intCast(k))) % 4;
                const set = dir_sets[d];
                var clear = true;
                for (set) |nb| {
                    if (occ[idx(x + nb[0], y + nb[1])] != 0) clear = false;
                }
                if (clear) {
                    proposed = @bitCast(idx(x + set[0][0], y + set[0][1]));
                    break;
                }
            }
            targets.appendAssumeCapacity(proposed);
            if (proposed >= 0) {
                const c: u32 = @bitCast(proposed);
                if (counts[c] < 255) counts[c] += 1;
                touched.append(gpa, c) catch return false;
            }
        }

        var moved = false;
        for (0..n) |i| {
            const t = targets.items[i];
            if (t >= 0) {
                const c: u32 = @bitCast(t);
                if (counts[c] == 1) {
                    const from = idx(s.xs.items[i], s.ys.items[i]);
                    occ[from] = 0;
                    occ[c] = 1;
                    s.xs.items[i] = @as(i32, @intCast(c % GW)) - OFF;
                    s.ys.items[i] = @as(i32, @intCast(c / GW)) - OFF;
                    moved = true;
                }
            }
        }
        return moved;
    }
};

pub fn main() !void {
    {
        // part 1: 10 rounds, empty cells in the bounding box
        @memset(&occ, 0);
        var s = try Sim.init();
        var r: u8 = 0;
        while (r < 10) : (r += 1) _ = s.round(r % 4);
        var lo = [2]i32{ std.math.maxInt(i32), std.math.maxInt(i32) };
        var hi = [2]i32{ std.math.minInt(i32), std.math.minInt(i32) };
        for (s.xs.items, s.ys.items) |x, y| {
            lo[0] = @min(lo[0], x);
            lo[1] = @min(lo[1], y);
            hi[0] = @max(hi[0], x);
            hi[1] = @max(hi[1], y);
        }
        const area = (hi[0] - lo[0] + 1) * (hi[1] - lo[1] + 1);
        print("part 1: {d}\n", .{area - @as(i32, @intCast(s.xs.items.len))});
    }
    {
        // part 2: rounds until nobody moves
        @memset(&occ, 0);
        var s = try Sim.init();
        var r: usize = 0;
        while (true) : (r += 1) {
            if (!s.round(@intCast(r % 4))) {
                print("part 2: {d}\n", .{r + 1});
                break;
            }
        }
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
