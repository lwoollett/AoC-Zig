const std = @import("std");
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

const MAX_RID: usize = 255;
const MAX_LEN: usize = 127; // end-position bitmask is u128

var rules: [MAX_RID + 1]?Rule = @splat(null);
var n_rules: usize = 0;

/// dp[rid][p] = bitmask of end positions e such that rule rid matches
/// msg[p..e]. Recomputed per message (results depend on the message, so
/// the memo must not leak across them).
var dp: []u128 = &.{}; // (MAX_RID+1) * (MAX_LEN+1)
var computed: []bool = &.{};

fn bit(i: usize) u128 {
    return @as(u128, 1) << @intCast(i);
}

var msg: []const u8 = &.{};

fn matchAt(rid: usize, p: usize) u128 {
    const slot = rid * (MAX_LEN + 1) + p;
    if (computed[slot]) return dp[slot];
    var res: u128 = 0;
    if (rid <= MAX_RID) {
        if (rules[rid]) |rule| {
            if (rule.literal) |lit| {
                if (p < msg.len and msg[p] == lit) res = bit(p + 1);
            } else {
                for (rule.alts) |alt| {
                    var acc: u128 = bit(p);
                    for (alt) |sub| {
                        var nacc: u128 = 0;
                        var m = acc;
                        while (m != 0) {
                            const e: usize = @ctz(m);
                            nacc |= matchAt(sub, e);
                            m &= m - 1;
                        }
                        acc = nacc;
                        if (acc == 0) break;
                    }
                    res |= acc;
                }
            }
        }
    }
    computed[slot] = true;
    dp[slot] = res;
    return res;
}

fn parseRules() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) break;
        // "1: 2 3 | 3 2" or '4: "a"'
        const colon = indexOf(u8, line, ':') orelse break;
        const rid = try parseInt(usize, line[0..colon], 10);
        const rest = trim(u8, line[colon + 1 ..], " ");
        n_rules = @max(n_rules, rid);
        if (rest[0] == '"') {
            rules[rid] = .{ .literal = rest[1] };
            continue;
        }
        var alts: std.ArrayList(Alt) = .empty;
        var alt_it = splitSca(u8, rest, '|');
        while (alt_it.next()) |alt_raw| {
            var seq: std.ArrayList(usize) = .empty;
            var num_it = tokenizeAny(u8, alt_raw, " ");
            while (num_it.next()) |num| {
                try seq.append(gpa, try parseInt(usize, num, 10));
            }
            try alts.append(gpa, try seq.toOwnedSlice(gpa));
        }
        rules[rid] = .{ .alts = try alts.toOwnedSlice(gpa) };
    }
}

fn countMatches() !u32 {
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
        if (line.len >= MAX_LEN) return error.MessageTooLong;
        msg = line;
        for (0..n_rules + 1) |rid| {
            @memset(computed[rid * (MAX_LEN + 1) ..][0 .. line.len + 1], false);
        }
        if (matchAt(0, 0) & bit(line.len) != 0) count += 1;
    }
    return count;
}

pub fn main() !void {
    try parseRules();
    dp = try gpa.alloc(u128, (MAX_RID + 1) * (MAX_LEN + 1));
    defer gpa.free(dp);
    computed = try gpa.alloc(bool, (MAX_RID + 1) * (MAX_LEN + 1));
    defer gpa.free(computed);
    print("part 1: {d}\n", .{try countMatches()});

    // part 2: loop rules
    // 8: 42 | 42 8
    {
        const alt1 = try gpa.alloc(usize, 1);
        alt1[0] = 42;
        const alt2 = try gpa.alloc(usize, 2);
        alt2[0] = 42;
        alt2[1] = 8;
        const alts = try gpa.alloc(Alt, 2);
        alts[0] = alt1;
        alts[1] = alt2;
        rules[8] = .{ .alts = alts };
    }
    // 11: 42 31 | 42 11 31
    {
        const alt1 = try gpa.alloc(usize, 2);
        alt1[0] = 42;
        alt1[1] = 31;
        const alt2 = try gpa.alloc(usize, 3);
        alt2[0] = 42;
        alt2[1] = 11;
        alt2[2] = 31;
        const alts = try gpa.alloc(Alt, 2);
        alts[0] = alt1;
        alts[1] = alt2;
        rules[11] = .{ .alts = alts };
    }
    print("part 2: {d}\n", .{try countMatches()});
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
