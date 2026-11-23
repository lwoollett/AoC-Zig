const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day05.txt");

fn run(strict: bool) !u64 {
    var jumps: List(i64) = .empty;
    defer jumps.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        try jumps.append(gpa, try parseInt(i64, line, 10));
    }
    var pc: i64 = 0;
    var steps: u64 = 0;
    while (pc >= 0 and pc < jumps.items.len) {
        const i: usize = @intCast(pc);
        const off = jumps.items[i];
        if (strict) {
            jumps.items[i] = if (off >= 3) off - 1 else off + 1;
        } else {
            jumps.items[i] = off + 1;
        }
        pc += off;
        steps += 1;
    }
    return steps;
}

pub fn main() !void {
    print("part 1: {d}\n", .{try run(false)});
    print("part 2: {d}\n", .{try run(true)});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
