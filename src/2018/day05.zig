const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day05.txt");

fn reacts(a: u8, b: u8) bool {
    return (a | 0x20) == (b | 0x20) and a != b;
}

/// Reduce polymer with a stack; `skip` removes one letter type (both cases).
fn reducedLen(input: []const u8, skip: u8) !usize {
    var stack: List(u8) = .empty;
    defer stack.deinit(gpa);
    for (input) |c| {
        if ((c | 0x20) == skip) continue;
        if (stack.items.len > 0 and reacts(stack.items[stack.items.len - 1], c)) {
            _ = stack.pop();
        } else {
            try stack.append(gpa, c);
        }
    }
    return stack.items.len;
}

pub fn main() !void {
    const polymer = trim(u8, data, " \n\r\t");

    print("part 1: {d}\n", .{try reducedLen(polymer, 0)});

    var best: usize = std.math.maxInt(usize);
    var letter: u8 = 'a';
    while (letter <= 'z') : (letter += 1) {
        best = @min(best, try reducedLen(polymer, letter));
    }
    print("part 2: {d}\n", .{best});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
