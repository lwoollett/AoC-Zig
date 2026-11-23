const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day21.txt");

const Item = struct { cost: u32, dmg: u32, arm: u32 };

const weapons = [_]Item{
    .{ .cost = 8, .dmg = 4, .arm = 0 },
    .{ .cost = 10, .dmg = 5, .arm = 0 },
    .{ .cost = 25, .dmg = 6, .arm = 0 },
    .{ .cost = 40, .dmg = 7, .arm = 0 },
    .{ .cost = 74, .dmg = 8, .arm = 0 },
};

const armors = [_]Item{
    .{ .cost = 0, .dmg = 0, .arm = 0 },
    .{ .cost = 13, .dmg = 0, .arm = 1 },
    .{ .cost = 31, .dmg = 0, .arm = 2 },
    .{ .cost = 53, .dmg = 0, .arm = 3 },
    .{ .cost = 75, .dmg = 0, .arm = 4 },
    .{ .cost = 102, .dmg = 0, .arm = 5 },
};

const rings = [_]Item{
    .{ .cost = 25, .dmg = 1, .arm = 0 },
    .{ .cost = 50, .dmg = 2, .arm = 0 },
    .{ .cost = 100, .dmg = 3, .arm = 0 },
    .{ .cost = 20, .dmg = 0, .arm = 1 },
    .{ .cost = 40, .dmg = 0, .arm = 2 },
    .{ .cost = 80, .dmg = 0, .arm = 3 },
};

/// True iff the player (100 hp) wins a trading-blow fight.
fn playerWins(player_dmg: u32, player_arm: u32, boss_hp: u32, boss_dmg: u32, boss_arm: u32) bool {
    const p_dmg_per_hit = @max(1, player_dmg -| boss_arm);
    const b_dmg_per_hit = @max(1, boss_dmg -| player_arm);
    const player_turns = (boss_hp + p_dmg_per_hit - 1) / p_dmg_per_hit;
    const boss_turns = (100 + b_dmg_per_hit - 1) / b_dmg_per_hit;
    return player_turns <= boss_turns; // player swings first
}

const none = Item{ .cost = 0, .dmg = 0, .arm = 0 };

pub fn main() !void {
    var boss_hp: u32 = 0;
    var boss_dmg: u32 = 0;
    var boss_arm: u32 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "Hit Points:")) {
            boss_hp = try parseInt(u32, trim(u8, line["Hit Points:".len..], " "), 10);
        } else if (std.mem.startsWith(u8, line, "Damage:")) {
            boss_dmg = try parseInt(u32, trim(u8, line["Damage:".len..], " "), 10);
        } else if (std.mem.startsWith(u8, line, "Armor:")) {
            boss_arm = try parseInt(u32, trim(u8, line["Armor:".len..], " "), 10);
        }
    }

    var min_win_cost: u32 = std.math.maxInt(u32);
    var max_lose_cost: u32 = 0;

    // All ring choices: none, each single, and every distinct pair.
    var ring_combos: [22][2]Item = undefined;
    var n_combos: usize = 0;
    ring_combos[n_combos] = .{ none, none };
    n_combos += 1;
    for (rings) |r| {
        ring_combos[n_combos] = .{ r, none };
        n_combos += 1;
    }
    for (rings, 0..) |ra, i| {
        for (rings[i + 1 ..]) |rb| {
            ring_combos[n_combos] = .{ ra, rb };
            n_combos += 1;
        }
    }

    for (weapons) |w| {
        for (armors) |a| {
            for (ring_combos[0..n_combos]) |rc| {
                const r1 = rc[0];
                const r2 = rc[1];
                const cost = w.cost + a.cost + r1.cost + r2.cost;
                const dmg = w.dmg + r1.dmg + r2.dmg;
                const arm = a.arm + r1.arm + r2.arm;
                if (playerWins(dmg, arm, boss_hp, boss_dmg, boss_arm)) {
                    min_win_cost = @min(min_win_cost, cost);
                } else {
                    max_lose_cost = @max(max_lose_cost, cost);
                }
            }
        }
    }

    print("part 1: {d}\n", .{min_win_cost});
    print("part 2: {d}\n", .{max_lose_cost});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
