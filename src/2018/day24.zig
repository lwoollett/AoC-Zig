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

const max_types = 10;

const Group = struct {
    immune_system: bool,
    units: i64,
    hp: i64,
    attack: i64,
    attack_type: u4, // index into the type table
    initiative: i32,
    weak: u16,
    immune: u16,
    target: i32 = -1,
};

var type_names: [max_types][16]u8 = undefined;
var type_lens: [max_types]usize = @splat(0);
var n_types: usize = 0;

fn typeId(name: []const u8) u4 {
    for (0..n_types) |i| {
        if (std.mem.eql(u8, type_names[i][0..type_lens[i]], name)) return @intCast(i);
    }
    const i = n_types;
    n_types += 1;
    @memcpy(type_names[i][0..name.len], name);
    type_lens[i] = name.len;
    return @intCast(i);
}

fn effectivePower(g: *const Group) i64 {
    return g.units * g.attack;
}

fn damageDealt(a: *const Group, d: *const Group) i64 {
    if (d.immune & (@as(u16, 1) << a.attack_type) != 0) return 0;
    var mult: i64 = 1;
    if (d.weak & (@as(u16, 1) << a.attack_type) != 0) mult = 2;
    return effectivePower(a) * mult;
}

/// Runs a full battle; returns (immune_units, infection_units), or null on
/// stalemate. boost adds to immune-system attack.
fn battle(boost: i64) ?[2]i64 {
    var groups: List(Group) = .empty;
    defer groups.deinit(gpa);

    var current_immune = false;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) continue;
        if (std.mem.find(u8, line, "Immune System:") != null) {
            current_immune = true;
            continue;
        }
        if (std.mem.find(u8, line, "Infection:") != null) {
            current_immune = false;
            continue;
        }
        if (std.mem.findScalar(u8, line, 'u') == null) continue;

        var g = Group{
            .immune_system = current_immune,
            .units = 0,
            .hp = 0,
            .attack = 0,
            .attack_type = 0,
            .initiative = 0,
            .weak = 0,
            .immune = 0,
        };
        // "18 units each with 729 hit points (weak to fire; immune to cold, slashing) with an attack that does 8 bludgeoning damage at initiative 8"
        var it = tokenizeAny(u8, line, " ");
        g.units = parseInt(i64, it.next().?, 10) catch continue;
        _ = it.next().?; // units
        _ = it.next().?; // each
        _ = it.next().?; // with
        g.hp = parseInt(i64, it.next().?, 10) catch continue; // number
        _ = it.next().?; // hit
        _ = it.next().?; // points
        const tok = it.next().?; // "with" or "("
        if (tok[0] == '(') {
            // e.g. "(weak to fire; immune to cold, slashing)" — strip () , ;
            var mode: u8 = 0; // 1=weak 2=immune
            while (it.next()) |raw| {
                var t = raw;
                var done = false;
                if (t[t.len - 1] == ')') {
                    t = t[0 .. t.len - 1];
                    done = true;
                }
                if (t.len > 0 and t[0] == '(') t = t[1..];
                while (t.len > 0 and (t[t.len - 1] == ',' or t[t.len - 1] == ';')) t = t[0 .. t.len - 1];
                if (std.mem.eql(u8, t, "weak")) {
                    mode = 1;
                } else if (std.mem.eql(u8, t, "immune")) {
                    mode = 2;
                } else if (t.len > 0 and !std.mem.eql(u8, t, "to")) {
                    const id = typeId(t);
                    if (mode == 1) g.weak |= @as(u16, 1) << id;
                    if (mode == 2) g.immune |= @as(u16, 1) << id;
                }
                if (done) break;
            }
            _ = it.next().?; // "with" follows the ')'
        }
        _ = it.next().?; // an
        _ = it.next().?; // attack
        _ = it.next().?; // that
        _ = it.next().?; // does
        g.attack = parseInt(i64, it.next().?, 10) catch continue;
        g.attack_type = typeId(it.next().?);
        _ = it.next().?; // damage
        _ = it.next().?; // at
        _ = it.next().?; // initiative
        g.initiative = parseInt(i32, it.next().?, 10) catch continue;

        if (g.immune_system) g.attack += boost;
        groups.append(gpa, g) catch return null;
    }

    // fight rounds
    while (true) {
        var immune_alive: i64 = 0;
        var infection_alive: i64 = 0;
        for (groups.items) |g| {
            if (g.units > 0) {
                if (g.immune_system) immune_alive += g.units else infection_alive += g.units;
            }
        }
        if (immune_alive == 0 or infection_alive == 0) return .{ immune_alive, infection_alive };

        // target selection
        for (groups.items) |*g| g.target = -1;
        var order: List(usize) = .empty;
        defer order.deinit(gpa);
        for (groups.items, 0..) |g, i| {
            if (g.units > 0) order.append(gpa, i) catch return null;
        }
        std.mem.sort(usize, order.items, groups.items, struct {
            fn lessThan(gs: []Group, a: usize, b: usize) bool {
                const pa = effectivePower(&gs[a]);
                const pb = effectivePower(&gs[b]);
                if (pa != pb) return pa > pb;
                return gs[a].initiative > gs[b].initiative;
            }
        }.lessThan);
        var targeted: u32 = 0;
        for (order.items) |ai| {
            const a = &groups.items[ai];
            var best: i32 = -1;
            var best_dmg: i64 = -1;
            for (groups.items, 0..) |*d, di| {
                if (d.units <= 0 or d.immune_system == a.immune_system) continue;
                if (d.target != -1) continue;
                const dmg = damageDealt(a, d);
                if (dmg == 0) continue;
                if (dmg > best_dmg or (dmg == best_dmg and
                    (effectivePower(d) > effectivePower(&groups.items[@intCast(best)]) or
                        (effectivePower(d) == effectivePower(&groups.items[@intCast(best)]) and d.initiative > groups.items[@intCast(best)].initiative))))
                {
                    best_dmg = dmg;
                    best = @intCast(di);
                }
            }
            if (best != -1) {
                groups.items[@intCast(best)].target = @intCast(ai);
                targeted += 1;
            }
        }
        if (targeted == 0) return null; // stalemate

        // attack by initiative
        var atk_order: List(usize) = .empty;
        defer atk_order.deinit(gpa);
        for (groups.items, 0..) |g, i| {
            if (g.units > 0) atk_order.append(gpa, i) catch return null;
        }
        std.mem.sort(usize, atk_order.items, groups.items, struct {
            fn lessThan(gs: []Group, a: usize, b: usize) bool {
                return gs[a].initiative > gs[b].initiative;
            }
        }.lessThan);
        var killed: i64 = 0;
        for (atk_order.items) |ai| {
            const a = &groups.items[ai];
            if (a.units <= 0) continue;
            const ti = a.target;
            if (ti < 0) continue;
            const d = &groups.items[@intCast(ti)];
            if (d.units <= 0) continue;
            const dmg = damageDealt(a, d);
            const kills = @divTrunc(dmg, d.hp);
            if (kills > 0) {
                d.units -= kills;
                killed += kills;
            }
        }
        if (killed == 0) return null; // stalemate
    }
}

pub fn main() !void {
    const r1 = (battle(0) orelse return error.Stalemate);
    print("part 1: {d}\n", .{@max(r1[0], r1[1])});

    var boost: i64 = 1;
    while (boost < 2000) : (boost += 1) {
        if (battle(boost)) |r| {
            if (r[1] == 0 and r[0] > 0) {
                print("part 2: {d}\n", .{r[0]});
                return;
            }
        }
    }
    return error.NoBoostWorks;
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
