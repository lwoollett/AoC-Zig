const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day15.txt");

const gw = 40;
const gh = 40;

const Unit = struct {
    elf: bool,
    x: usize,
    y: usize,
    hp: i32 = 200,
    attack: i32 = 3,
    alive: bool = true,
};

var walls: [gh][gw]bool = @splat(@splat(false));
var units: List(Unit) = .empty;
var w: usize = 0;
var h: usize = 0;

// occupancy grid: unit index + 1, 0 = empty (unitAt was an O(units) scan
// called from inside every BFS neighbour check — the sim's hot inner loop)
var occ: [gh][gw]u8 = @splat(@splat(0));

fn unitAt(x: usize, y: usize) ?usize {
    const v = occ[y][x];
    return if (v == 0) null else v - 1;
}

fn occupied(x: usize, y: usize) bool {
    return walls[y][x] or unitAt(x, y) != null;
}

/// BFS distances from (x,y) over open squares (units block).
fn bfsFrom(x: usize, y: usize, dist: *[gh][gw]i32) void {
    for (dist) |*row| @memset(row, -1);
    dist[y][x] = 0;
    var qx = List(usize).empty;
    var qy = List(usize).empty;
    defer qx.deinit(gpa);
    defer qy.deinit(gpa);
    qx.append(gpa, x) catch {};
    qy.append(gpa, y) catch {};
    var qi: usize = 0;
    while (qi < qx.items.len) : (qi += 1) {
        const cx = qx.items[qi];
        const cy = qy.items[qi];
        const d = dist[cy][cx];
        const moves = [4][2]i32{ .{ 0, -1 }, .{ -1, 0 }, .{ 1, 0 }, .{ 0, 1 } };
        for (moves) |m| {
            const nx = @as(i64, @intCast(cx)) + m[0];
            const ny = @as(i64, @intCast(cy)) + m[1];
            if (nx < 0 or ny < 0) continue;
            const ux: usize = @intCast(nx);
            const uy: usize = @intCast(ny);
            if (ux >= w or uy >= h) continue;
            if (walls[uy][ux]) continue;
            if (dist[uy][ux] != -1) continue;
            if (unitAt(ux, uy) != null and !(ux == x and uy == y)) continue;
            dist[uy][ux] = d + 1;
            qx.append(gpa, ux) catch {};
            qy.append(gpa, uy) catch {};
        }
    }
}

/// One combat; returns (rounds completed, surviving units) or null if an
/// elf died (only checked when `elf_must_live`).
fn combat(elf_attack: i32, elf_must_live: bool) !?struct { rounds: u32, sum_hp: i64 } {
    // reset units from the parsed original state
    units.clearRetainingCapacity();
    var lines = tokenizeAny(u8, data, "\n");
    var y: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        w = @max(w, line.len);
        for (line, 0..) |c, x| {
            walls[y][x] = c == '#';
            switch (c) {
                'E' => try units.append(gpa, .{ .elf = true, .x = x, .y = y, .attack = elf_attack }),
                'G' => try units.append(gpa, .{ .elf = false, .x = x, .y = y }),
                else => {},
            }
        }
        h = y + 1;
        y += 1;
    }

    for (0..gh) |yy| @memset(&occ[yy], 0);
    for (units.items, 0..) |u, i| occ[u.y][u.x] = @intCast(i + 1);

    var rounds: u32 = 0;
    while (true) {
        // acting order: reading order
        var order: List(usize) = .empty;
        defer order.deinit(gpa);
        for (units.items, 0..) |u, i| {
            if (u.alive) try order.append(gpa, i);
        }
        std.mem.sort(usize, order.items, units.items, struct {
            fn lessThan(us: []Unit, a: usize, b: usize) bool {
                if (us[a].y != us[b].y) return us[a].y < us[b].y;
                return us[a].x < us[b].x;
            }
        }.lessThan);

        var combat_ended_early = false;
        for (order.items) |ui| {
            if (!units.items[ui].alive) continue;
            // any enemies left?
            var has_enemy = false;
            for (units.items) |u| {
                if (u.alive and u.elf != units.items[ui].elf) has_enemy = true;
            }
            if (!has_enemy) {
                combat_ended_early = true;
                break;
            }
            try takeTurn(ui);
            if (elf_must_live) {
                for (units.items) |u| {
                    if (u.elf and !u.alive) return null;
                }
            }
        }
        if (combat_ended_early) break;
        rounds += 1;
    }

    var sum_hp: i64 = 0;
    for (units.items) |u| {
        if (u.alive) sum_hp += u.hp;
    }
    return .{ .rounds = rounds, .sum_hp = sum_hp };
}

fn takeTurn(ui: usize) !void {
    var me = &units.items[ui];
    const enemy_kind = !me.elf;

    // adjacent enemy?
    var target: ?usize = null;
    const adj = [4][2]i32{ .{ 0, -1 }, .{ -1, 0 }, .{ 1, 0 }, .{ 0, 1 } };
    for (adj) |m| {
        const nx = @as(i64, @intCast(me.x)) + m[0];
        const ny = @as(i64, @intCast(me.y)) + m[1];
        if (nx < 0 or ny < 0) continue;
        const ux: usize = @intCast(nx);
        const uy: usize = @intCast(ny);
        if (ux >= w or uy >= h) continue;
        if (unitAt(ux, uy)) |oi| {
            const o = &units.items[oi];
            if (o.alive and o.elf == enemy_kind) {
                // pick lowest hp (tie: reading order — adj order is reading order)
                if (target == null or o.hp < units.items[target.?].hp) target = oi;
            }
        }
    }

    if (target == null) {
        // move: BFS from me; find nearest open square adjacent to an enemy
        var dist: [gh][gw]i32 = undefined;
        bfsFrom(me.x, me.y, &dist);

        var best_d: i32 = std.math.maxInt(i32);
        var best_x: usize = 0;
        var best_y: usize = 0;
        for (units.items) |u| {
            if (!u.alive or u.elf != enemy_kind) continue;
            for (adj) |m| {
                const nx = @as(i64, @intCast(u.x)) + m[0];
                const ny = @as(i64, @intCast(u.y)) + m[1];
                if (nx < 0 or ny < 0) continue;
                const ux: usize = @intCast(nx);
                const uy: usize = @intCast(ny);
                if (ux >= w or uy >= h) continue;
                if (occupied(ux, uy)) continue;
                const d = dist[uy][ux];
                if (d <= 0) continue;
                if (d < best_d or (d == best_d and (uy < best_y or (uy == best_y and ux < best_x)))) {
                    best_d = d;
                    best_x = ux;
                    best_y = uy;
                }
            }
        }
        if (best_d != std.math.maxInt(i32)) {
            // pick the first step: neighbor of me with dist == best_d - 1,
            // in reading order among such neighbors
            var sd: [gh][gw]i32 = undefined;
            bfsFrom(best_x, best_y, &sd);
            var step: ?[2]usize = null;
            for (adj) |m| {
                const nx = @as(i64, @intCast(me.x)) + m[0];
                const ny = @as(i64, @intCast(me.y)) + m[1];
                if (nx < 0 or ny < 0) continue;
                const ux: usize = @intCast(nx);
                const uy: usize = @intCast(ny);
                if (ux >= w or uy >= h) continue;
                if (walls[uy][ux]) continue;
                if (unitAt(ux, uy) != null) continue;
                if (sd[uy][ux] == best_d - 1) {
                    step = .{ ux, uy };
                    break;
                }
            }
            if (step) |s| {
                occ[me.y][me.x] = 0;
                me.x = s[0];
                me.y = s[1];
                occ[me.y][me.x] = @intCast(ui + 1);
            }
        }
        // re-check adjacency after moving
        me = &units.items[ui];
        for (adj) |m| {
            const nx = @as(i64, @intCast(me.x)) + m[0];
            const ny = @as(i64, @intCast(me.y)) + m[1];
            if (nx < 0 or ny < 0) continue;
            const ux: usize = @intCast(nx);
            const uy: usize = @intCast(ny);
            if (ux >= w or uy >= h) continue;
            if (unitAt(ux, uy)) |oi| {
                const o = &units.items[oi];
                if (o.alive and o.elf == enemy_kind) {
                    if (target == null or o.hp < units.items[target.?].hp) target = oi;
                }
            }
        }
    }

    if (target) |ti| {
        units.items[ti].hp -= units.items[ui].attack;
        if (units.items[ti].hp <= 0) {
            units.items[ti].alive = false;
            occ[units.items[ti].y][units.items[ti].x] = 0;
        }
    }
}

pub fn main() !void {
    units = .empty;
    const r1 = (try combat(3, false)).?;
    print("part 1: {d}\n", .{@as(i64, r1.rounds) * r1.sum_hp});

    var atk: i32 = 4;
    while (atk < 200) : (atk += 1) {
        if (try combat(atk, true)) |r| {
            print("part 2: {d}\n", .{@as(i64, r.rounds) * r.sum_hp});
            return;
        }
    }
    return error.NoElfAttackWorks;
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;
const sort = std.sort.block;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
