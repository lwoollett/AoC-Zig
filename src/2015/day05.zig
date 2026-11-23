const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day05.txt");

fn countVowels(s: []const u8) usize {
    var n: usize = 0;
    for (s) |c| {
        switch (c) {
            'a', 'e', 'i', 'o', 'u' => n += 1,
            else => {},
        }
    }
    return n;
}

fn hasDouble(s: []const u8) bool {
    var i: usize = 0;
    while (i + 1 < s.len) : (i += 1) {
        if (s[i] == s[i + 1]) return true;
    }
    return false;
}

fn hasForbidden(s: []const u8) bool {
    return std.mem.find(u8, s, "ab") != null or
        std.mem.find(u8, s, "cd") != null or
        std.mem.find(u8, s, "pq") != null or
        std.mem.find(u8, s, "xy") != null;
}

fn hasRepeatedPair(s: []const u8) bool {
    // A pair (xy) that appears again without overlapping.
    var i: usize = 0;
    while (i + 1 < s.len) : (i += 1) {
        const pair = s[i .. i + 2];
        if (std.mem.findPos(u8, s, i + 2, pair) != null) return true;
    }
    return false;
}

fn hasSandwich(s: []const u8) bool {
    var i: usize = 0;
    while (i + 2 < s.len) : (i += 1) {
        if (s[i] == s[i + 2]) return true;
    }
    return false;
}

pub fn main() !void {
    var nice1: usize = 0;
    var nice2: usize = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (countVowels(line) >= 3 and hasDouble(line) and !hasForbidden(line)) nice1 += 1;
        if (hasRepeatedPair(line) and hasSandwich(line)) nice2 += 1;
    }

    print("part 1: {d}\n", .{nice1});
    print("part 2: {d}\n", .{nice2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
