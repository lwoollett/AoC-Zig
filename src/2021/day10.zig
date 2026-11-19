const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day10.txt");

fn closes(open: u8, close: u8) bool {
    return (open == '(' and close == ')') or
        (open == '[' and close == ']') or
        (open == '{' and close == '}') or
        (open == '<' and close == '>');
}

fn corruptScore(c: u8) u64 {
    return switch (c) {
        ')' => 3,
        ']' => 57,
        '}' => 1197,
        else => 25137,
    };
}

fn closer(open: u8) u8 {
    return switch (open) {
        '(' => ')',
        '[' => ']',
        '{' => '}',
        else => '>',
    };
}

fn autocompleteScore(c: u8) u64 {
    return switch (c) {
        ')' => 1,
        ']' => 2,
        '}' => 3,
        else => 4,
    };
}

pub fn main() !void {
    var total_corrupt: u64 = 0;
    var scores: List(u64) = .empty;
    defer scores.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var stack: [256]u8 = undefined;
        var depth: usize = 0;
        var corrupt = false;
        for (line) |c| {
            if (c == '(' or c == '[' or c == '{' or c == '<') {
                stack[depth] = c;
                depth += 1;
            } else {
                if (depth == 0 or !closes(stack[depth - 1], c)) {
                    total_corrupt += corruptScore(c);
                    corrupt = true;
                    break;
                }
                depth -= 1;
            }
        }
        if (corrupt) continue;
        var score: u64 = 0;
        while (depth > 0) {
            depth -= 1;
            score = score * 5 + autocompleteScore(closer(stack[depth]));
        }
        try scores.append(gpa, score);
    }

    print("part 1: {d}\n", .{total_corrupt});
    std.mem.sort(u64, scores.items, {}, comptime std.sort.asc(u64));
    print("part 2: {d}\n", .{scores.items[scores.items.len / 2]});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;
const sort = std.sort.block;
const asc = std.sort.asc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
