const std = @import("std");
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day19.txt");

const Rule = struct { from: []const u8, to: []const u8 };

pub fn main() !void {
    var rules: List(Rule) = .empty;
    defer rules.deinit(gpa);
    var medicine: []const u8 = "";

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (std.mem.find(u8, line, "=>") == null) {
            if (line.len > 0) medicine = line;
            continue;
        }
        var it = tokenizeAny(u8, line, " ");
        const from = it.next().?;
        _ = it.next().?; // =>
        const to = it.next().?;
        try rules.append(gpa, .{ .from = from, .to = to });
    }

    // Part 1: distinct molecules after exactly one replacement.
    // The map owns its keys (slices are not copied on put).
    var seen = StrMap(void).init(gpa);
    defer {
        var kit = seen.keyIterator();
        while (kit.next()) |k| gpa.free(k.*);
        seen.deinit();
    }
    for (rules.items) |rule| {
        var pos: usize = 0;
        while (std.mem.findPos(u8, medicine, pos, rule.from)) |idx| {
            const buf = try std.mem.concat(gpa, u8, &.{
                medicine[0..idx], rule.to, medicine[idx + rule.from.len ..],
            });
            if (seen.contains(buf)) {
                gpa.free(buf);
            } else {
                try seen.put(buf, {});
            }
            pos = idx + 1;
        }
    }
    print("part 1: {d}\n", .{seen.count()});

    // Part 2: greedily run replacements in reverse (longest RHS first),
    // replacing one occurrence per step, until we reach "e".
    var mol = try gpa.dupe(u8, medicine);
    defer gpa.free(mol);

    // Sort rules by RHS length descending for a deterministic greedy order.
    std.mem.sort(Rule, rules.items, {}, struct {
        fn lessThan(_: void, a: Rule, b: Rule) bool {
            return a.to.len > b.to.len;
        }
    }.lessThan);

    var steps: usize = 0;
    var guard: usize = 0;
    while (!std.mem.eql(u8, mol, "e")) : (guard += 1) {
        if (guard > 100_000) return error.NoReduction;
        var replaced = false;
        for (rules.items) |rule| {
            const idx = std.mem.find(u8, mol, rule.to) orelse continue;
            const buf = try std.mem.concat(gpa, u8, &.{
                mol[0..idx], rule.from, mol[idx + rule.to.len ..],
            });
            gpa.free(mol);
            mol = buf;
            steps += 1;
            replaced = true;
            break;
        }
        if (!replaced) return error.Stuck;
    }
    print("part 2: {d}\n", .{steps});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;
const sort = std.sort.block;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
