const std = @import("std");
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day07.txt");

const max_progs = 2000;

const Prog = struct {
    name: []const u8,
    weight: u32,
    children: [16]u16 = @splat(0),
    n_children: u8 = 0,
    parent: i32 = -1,
    total: i64 = 0,
};

var progs: [max_progs]Prog = undefined;
var n_progs: usize = 0;

fn progId(name: []const u8, names: *StrMap(u16)) !u16 {
    if (names.get(name)) |id| return id;
    progs[n_progs] = .{ .name = try gpa.dupe(u8, name), .weight = 0 };
    try names.put(progs[n_progs].name, @intCast(n_progs));
    n_progs += 1;
    return @intCast(n_progs - 1);
}

fn totalOf(id: u16) i64 {
    if (progs[id].total != 0) return progs[id].total;
    var t: i64 = progs[id].weight;
    for (progs[id].children[0..progs[id].n_children]) |c| {
        t += totalOf(c);
    }
    progs[id].total = t;
    return t;
}

pub fn main() !void {
    var names = StrMap(u16).init(gpa);
    defer names.deinit();

    // parse all lines twice: first register names, then relations
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "name (weight) -> child, child" or "name (weight)"
        var it = tokenizeAny(u8, line, " (),->\t");
        const name = it.next().?;
        const weight = try parseInt(u32, it.next().?, 10);
        const id = try progId(name, &names);
        progs[id].weight = weight;
        while (it.next()) |child| {
            const cid = try progId(child, &names);
            const p = &progs[id];
            p.children[p.n_children] = cid;
            p.n_children += 1;
            progs[cid].parent = id;
        }
    }

    // root: no parent
    var root: u16 = 0;
    for (progs[0..n_progs], 0..) |p, i| {
        if (p.parent == -1) {
            root = @intCast(i);
            break;
        }
    }
    print("part 1: {s}\n", .{progs[root].name});

    // find the imbalance: walk down the wrong branch
    var node = root;
    var diff: i64 = 0;
    while (true) {
        const p = progs[node];
        // do all children agree?
        if (p.n_children == 0) break;
        const first = totalOf(p.children[0]);
        var odd_one: i16 = -1;
        var count_first: u8 = 0;
        for (p.children[0..p.n_children]) |c| {
            if (totalOf(c) == first) count_first += 1;
        }
        if (count_first == p.n_children) break; // balanced: node is the culprit
        // find the child that disagrees with the majority
        var majority: i64 = first;
        if (count_first == 1) {
            // first is the odd one
            for (p.children[0..p.n_children]) |c| {
                if (totalOf(c) != first) {
                    majority = totalOf(c);
                    break;
                }
            }
        }
        for (p.children[0..p.n_children]) |c| {
            if (totalOf(c) != majority) {
                odd_one = @intCast(c);
                break;
            }
        }
        diff = totalOf(@intCast(odd_one)) - majority;
        node = @intCast(odd_one);
    }

    print("part 2: {d}\n", .{@as(i64, progs[node].weight) - diff});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
