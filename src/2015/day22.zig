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

const player_hp0: i32 = 50;
const mana0: i32 = 500;

const Spell = enum(u8) { missile, drain, shield, poison, recharge };
const spells = [_]Spell{ .missile, .drain, .shield, .poison, .recharge };
const costs = [_]i32{ 53, 73, 113, 173, 229 };

var boss_hp0: i32 = 0;
var boss_dmg0: i32 = 0;

const Effects = struct { shield: u8 = 0, poison: u8 = 0, recharge: u8 = 0 };

var best_mana: i32 = std.math.maxInt(i32);

/// Applies poison/shield ticks; returns boss damage dealt by poison.
fn tick(e: *Effects) i32 {
    var dmg: i32 = 0;
    if (e.poison > 0) {
        dmg += 3;
        e.poison -= 1;
    }
    if (e.shield > 0) e.shield -= 1;
    return dmg;
}

/// Decrements the recharge timer and returns the mana gained this tick.
fn tickRecharge(e: *Effects) i32 {
    if (e.recharge > 0) {
        e.recharge -= 1;
        return 101;
    }
    return 0;
}

fn armor(e: Effects) i32 {
    return if (e.shield > 0) 7 else 0;
}

/// Exhaustive DFS over spell choices; prunes on spent >= best_mana.
fn play(spent_in: i32, php: i32, mana_in: i32, bhp_in: i32, e_in: Effects, hard: bool) void {
    if (spent_in >= best_mana) return;

    // --- player turn ---
    var hp = php;
    var boss = bhp_in;
    var mana = mana_in;
    var ef = e_in;
    if (hard) {
        hp -= 1;
        if (hp <= 0) return;
    }
    boss -= tick(&ef);
    mana += tickRecharge(&ef);
    if (boss <= 0) {
        best_mana = @min(best_mana, spent_in);
        return;
    }

    // cast a spell
    for (spells, 0..) |spell, si| {
        if (mana < costs[si]) continue;
        if (ef.shield > 0 and spell == .shield) continue;
        if (ef.poison > 0 and spell == .poison) continue;
        if (ef.recharge > 0 and spell == .recharge) continue;

        var m = mana - costs[si];
        var b = boss;
        var h = hp;
        var e2 = ef;
        switch (spell) {
            .missile => b -= 4,
            .drain => {
                b -= 2;
                h += 2;
            },
            .shield => e2.shield = 6,
            .poison => e2.poison = 6,
            .recharge => e2.recharge = 5,
        }
        if (b <= 0) {
            best_mana = @min(best_mana, spent_in + costs[si]);
            continue;
        }

        // --- boss turn ---
        b -= tick(&e2);
        m += tickRecharge(&e2);
        if (b <= 0) {
            best_mana = @min(best_mana, spent_in + costs[si]);
            continue;
        }
        h -= @max(1, boss_dmg0 - armor(e2));
        if (h <= 0) continue;

        play(spent_in + costs[si], h, m, b, e2, hard);
    }
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "Hit Points:")) {
            boss_hp0 = try parseInt(i32, trim(u8, line["Hit Points:".len..], " "), 10);
        } else if (std.mem.startsWith(u8, line, "Damage:")) {
            boss_dmg0 = try parseInt(i32, trim(u8, line["Damage:".len..], " "), 10);
        }
    }

    best_mana = std.math.maxInt(i32);
    play(0, player_hp0, mana0, boss_hp0, .{}, false);
    print("part 1: {d}\n", .{best_mana});

    best_mana = std.math.maxInt(i32);
    play(0, player_hp0, mana0, boss_hp0, .{}, true);
    print("part 2: {d}\n", .{best_mana});
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
