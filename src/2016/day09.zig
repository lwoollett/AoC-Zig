const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day09.txt");

/// Version 2 length: markers apply recursively, nothing materialized.
fn v2len(s: []const u8) u64 {
    var total: u64 = 0;
    var i: usize = 0;
    while (i < s.len) {
        if (s[i] == '(') {
            const close = std.mem.findScalar(u8, s[i..], ')').?;
            const inner = s[i + 1 .. i + close];
            const x = std.mem.findScalar(u8, inner, 'x').?;
            const count = parseInt(u32, inner[0..x], 10) catch 0;
            const times = parseInt(u32, inner[x + 1 ..], 10) catch 0;
            const span = @min(@as(usize, count), s.len - (i + close + 1));
            total += v2len(s[i + close + 1 .. i + close + 1 + span]) * times;
            i += close + 1 + span;
        } else {
            total += 1;
            i += 1;
        }
    }
    return total;
}

pub fn main() !void {
    const input = trim(u8, data, " \n\r\t");

    // Part 1: materialized decompression (one pass, no recursion).
    var out: List(u8) = .empty;
    defer out.deinit(gpa);
    var i: usize = 0;
    while (i < input.len) {
        if (input[i] == '(') {
            const close = std.mem.findScalar(u8, input[i..], ')').?;
            const inner = input[i + 1 .. i + close];
            const x = std.mem.findScalar(u8, inner, 'x').?;
            const count = parseInt(u32, inner[0..x], 10) catch 0;
            const times = parseInt(u32, inner[x + 1 ..], 10) catch 0;
            const span = @min(@as(usize, count), input.len - (i + close + 1));
            var t: u32 = 0;
            while (t < times) : (t += 1) {
                try out.appendSlice(gpa, input[i + close + 1 .. i + close + 1 + span]);
            }
            i += close + 1 + span;
        } else {
            try out.append(gpa, input[i]);
            i += 1;
        }
    }

    print("part 1: {d}\n", .{out.items.len});
    print("part 2: {d}\n", .{v2len(input)});
}

// Useful stdlib functions
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
