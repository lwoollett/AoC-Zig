const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day19.txt");

/// A rule alternative: a sequence of sub-rule numbers.
const Alt = []const usize;
const Rule = struct {
    literal: ?u8 = null, // 'a' or 'b'
    alts: []const Alt = &.{},
};

var rules = Map(usize, Rule).init(std.heap.page_allocator);
var memo = Map([2]usize, []usize).init(std.heap.page_allocator);

fn matchRule(rule_id: usize, s: []const u8, pos: usize) ![]usize {
    const key = [2]usize{ rule_id, pos };
    if (memo.get(key)) |v| return v;
    var ends: List(usize) = .empty;

    const rule = rules.get(rule_id) orelse return ends.items;
    if (rule.literal) |lit| {
        if (pos < s.len and s[pos] == lit) {
            try ends.append(gpa, pos + 1);
        }
    } else {
        for (rule.alts) |alt| {
            var positions: List(usize) = .empty;
            try positions.append(gpa, pos);
            for (alt) |sub| {
                var next_positions: List(usize) = .empty;
                for (positions.items) |p| {
                    const sub_ends = try matchRule(sub, s, p);
                    for (sub_ends) |e| {
                        var dup = false;
                        for (next_positions.items) |np| {
                            if (np == e) dup = true;
                        }
                        if (!dup) try next_positions.append(gpa, e);
                    }
                }
                positions.deinit(gpa);
                positions = next_positions;
                if (positions.items.len == 0) break;
            }
            for (positions.items) |e| {
                var dup = false;
                for (ends.items) |ex| {
                    if (ex == e) dup = true;
                }
                if (!dup) try ends.append(gpa, e);
            }
            positions.deinit(gpa);
        }
    }
    const result = ends.items;
    try memo.put(key, result);
    return result;
}

fn parseRules() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) break;
        // "1: 2 3 | 3 2" or '4: "a"'
        const colon = indexOf(u8, line, ':') orelse break;
        const rid = try parseInt(usize, line[0..colon], 10);
        const rest = trim(u8, line[colon + 1 ..], " ");
        if (rest[0] == '"') {
            try rules.put(rid, .{ .literal = rest[1] });
            continue;
        }
        var alts: List(Alt) = .empty;
        var alt_it = splitSca(u8, rest, '|');
        while (alt_it.next()) |alt_raw| {
            var seq: List(usize) = .empty;
            var num_it = tokenizeAny(u8, alt_raw, " ");
            while (num_it.next()) |num| {
                try seq.append(gpa, try parseInt(usize, num, 10));
            }
            try alts.append(gpa, try seq.toOwnedSlice(gpa));
        }
        try rules.put(rid, .{ .alts = try alts.toOwnedSlice(gpa) });
    }
}

fn countMatches() !u32 {
    memo.clearRetainingCapacity();
    var count: u32 = 0;
    var lines = splitSca(u8, data, '\n');
    var in_messages = false;
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) {
            in_messages = true;
            continue;
        }
        if (!in_messages) continue;
        memo.clearRetainingCapacity(); // memo keys omit the message string!
        const ends = try matchRule(0, line, 0);
        for (ends) |e| {
            if (e == line.len) {
                count += 1;
                break;
            }
        }
    }
    return count;
}

pub fn main() !void {
    try parseRules();
    print("part 1: {d}\n", .{try countMatches()});

    // part 2: loop rules
    // 8: 42 | 42 8
    {
        var alt1 = try gpa.alloc(usize, 1);
        alt1[0] = 42;
        var alt2 = try gpa.alloc(usize, 2);
        alt2[0] = 42;
        alt2[1] = 8;
        var alts = try gpa.alloc(Alt, 2);
        alts[0] = alt1;
        alts[1] = alt2;
        try rules.put(8, .{ .alts = alts });
    }
    // 11: 42 31 | 42 11 31
    {
        var alt1 = try gpa.alloc(usize, 2);
        alt1[0] = 42;
        alt1[1] = 31;
        var alt2 = try gpa.alloc(usize, 3);
        alt2[0] = 42;
        alt2[1] = 11;
        alt2[2] = 31;
        var alts = try gpa.alloc(Alt, 2);
        alts[0] = alt1;
        alts[1] = alt2;
        try rules.put(11, .{ .alts = alts });
    }
    print("part 2: {d}\n", .{try countMatches()});
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
