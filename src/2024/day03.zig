const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day03.txt");

fn scanMul(text: []const u8, comptime respect_dos: bool, total: *u64) void {
    var enabled = true;
    var i: usize = 0;
    while (i < text.len) {
        if (respect_dos and std.mem.startsWith(u8, text[i..], "do()")) {
            enabled = true;
            i += 4;
            continue;
        }
        if (respect_dos and std.mem.startsWith(u8, text[i..], "don't()")) {
            enabled = false;
            i += 7;
            continue;
        }
        if (std.mem.startsWith(u8, text[i..], "mul(")) {
            var j = i + 4;
            var a: u64 = 0;
            var digits: usize = 0;
            while (j < text.len and text[j] >= '0' and text[j] <= '9' and digits < 3) {
                a = a * 10 + (text[j] - '0');
                j += 1;
                digits += 1;
            }
            if (digits > 0 and j < text.len and text[j] == ',') {
                j += 1;
                var b: u64 = 0;
                digits = 0;
                while (j < text.len and text[j] >= '0' and text[j] <= '9' and digits < 3) {
                    b = b * 10 + (text[j] - '0');
                    j += 1;
                    digits += 1;
                }
                if (digits > 0 and j < text.len and text[j] == ')') {
                    if (enabled) {
                        total.* += a * b;
                    }
                    i = j + 1;
                    continue;
                }
            }
        }
        i += 1;
    }
}

pub fn main() !void {
    var t1: u64 = 0;
    scanMul(data, false, &t1);
    print("part 1: {d}\n", .{t1});
    var t2: u64 = 0;
    scanMul(data, true, &t2);
    print("part 2: {d}\n", .{t2});
}

// Useful stdlib functions

const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
