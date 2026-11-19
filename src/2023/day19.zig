const std = @import("std");
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day19.txt");

const Rule = struct {
    cat: u8, // x/m/a/s or 0 for catch-all
    op: u8, // '<' '>' or 0
    val: u64,
    target: []const u8,
};

var flows = StrMap(List(Rule)).init(std.heap.page_allocator);
var ratings: List([4]u64) = .empty;

fn catIndex(c: u8) usize {
    return switch (c) {
        'x' => 0,
        'm' => 1,
        'a' => 2,
        else => 3,
    };
}

fn applyFlow(name: []const u8, r: [4]u64) bool {
    var cur = name;
    while (true) {
        if (std.mem.eql(u8, cur, "A")) return true;
        if (std.mem.eql(u8, cur, "R")) return false;
        const rules = flows.get(cur).?;
        for (rules.items) |rule| {
            var matched = true;
            if (rule.cat != 0) {
                const v = r[catIndex(rule.cat)];
                matched = if (rule.op == '<') v < rule.val else v > rule.val;
            }
            if (matched) {
                cur = rule.target;
                break;
            }
        }
    }
}

/// range DFS: [4][2]u64 inclusive ranges
fn countRanges(name: []const u8, ranges: [4][2]u64) u128 {
    if (std.mem.eql(u8, name, "R")) return 0;
    if (std.mem.eql(u8, name, "A")) {
        var total: u128 = 1;
        for (ranges) |r| {
            total *= (r[1] - r[0] + 1);
        }
        return total;
    }
    var total: u128 = 0;
    var cur = ranges;
    for (flows.get(name).?.items) |rule| {
        if (rule.cat == 0) {
            total += countRanges(rule.target, cur);
            return total;
        }
        const ci = catIndex(rule.cat);
        const lo = cur[ci][0];
        const hi = cur[ci][1];
        if (rule.op == '<') {
            if (lo < rule.val) {
                var sub = cur;
                sub[ci][1] = rule.val - 1;
                total += countRanges(rule.target, sub);
                cur[ci][0] = rule.val;
                if (cur[ci][0] > cur[ci][1]) return total;
            }
        } else {
            if (hi > rule.val) {
                var sub = cur;
                sub[ci][0] = rule.val + 1;
                total += countRanges(rule.target, sub);
                cur[ci][1] = rule.val;
                if (cur[ci][0] > cur[ci][1]) return total;
            }
        }
    }
    return total;
}

pub fn main() !void {
    var lines = splitSca(u8, data, '\n');
    var in_ratings = false;
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) {
            in_ratings = true;
            continue;
        }
        if (!in_ratings) {
            // "px{a<2006:qkq,m>2090:A,rfg}"
            const brace = indexOf(u8, line, '{').?;
            const name = try std.heap.page_allocator.dupe(u8, line[0..brace]);
            const gop = try flows.getOrPut(name);
            if (!gop.found_existing) gop.value_ptr.* = .empty;
            var it = tokenizeAny(u8, line[brace + 1 .. line.len - 1], ",");
            while (it.next()) |rule_raw| {
                if (indexOf(u8, rule_raw, '<') != null or indexOf(u8, rule_raw, '>') != null) {
                    const colon = indexOf(u8, rule_raw, ':').?;
                    try gop.value_ptr.append(std.heap.page_allocator, .{
                        .cat = rule_raw[0],
                        .op = rule_raw[1],
                        .val = try parseInt(u64, rule_raw[2..colon], 10),
                        .target = try std.heap.page_allocator.dupe(u8, rule_raw[colon + 1 ..]),
                    });
                } else {
                    try gop.value_ptr.append(std.heap.page_allocator, .{
                        .cat = 0,
                        .op = 0,
                        .val = 0,
                        .target = try std.heap.page_allocator.dupe(u8, rule_raw),
                    });
                }
            }
        } else {
            // "{x=787,m=2655,a=1222,s=2876}"
            var r: [4]u64 = undefined;
            var it = tokenizeAny(u8, line[1 .. line.len - 1], ",=xmas");
            var i: usize = 0;
            while (it.next()) |tok| : (i += 1) {
                r[i] = try parseInt(u64, tok, 10);
            }
            try ratings.append(gpa, r);
        }
    }

    var total1: u64 = 0;
    for (ratings.items) |r| {
        if (applyFlow("in", r)) {
            total1 += r[0] + r[1] + r[2] + r[3];
        }
    }
    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{countRanges("in", .{ .{ 1, 4000 }, .{ 1, 4000 }, .{ 1, 4000 }, .{ 1, 4000 } })});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.findScalar;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
