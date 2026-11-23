const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day09.txt");

pub fn main() !void {
    var depth: u32 = 0;
    var score: u64 = 0;
    var garbage: u64 = 0;
    var in_garbage = false;

    var i: usize = 0;
    const s = trim(u8, data, " \n\r\t");
    while (i < s.len) : (i += 1) {
        const c = s[i];
        if (in_garbage) {
            switch (c) {
                '!' => i += 1, // skip next
                '>' => in_garbage = false,
                else => garbage += 1,
            }
        } else {
            switch (c) {
                '{' => {
                    depth += 1;
                    score += depth;
                },
                '}' => depth -= 1,
                '<' => in_garbage = true,
                else => {},
            }
        }
    }

    print("part 1: {d}\n", .{score});
    print("part 2: {d}\n", .{garbage});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
