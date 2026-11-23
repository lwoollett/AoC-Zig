const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day01.txt");

const words = [_][]const u8{ "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

fn calibration(line: []const u8, comptime words_on: bool) u32 {
    var first: u32 = 0;
    var last: u32 = 0;
    var found_first = false;

    for (line, 0..) |c, i| {
        var d: ?u32 = null;
        if (c >= '0' and c <= '9') {
            d = c - '0';
        } else if (words_on) {
            for (words, 0..) |wd, wi| {
                if (std.mem.startsWith(u8, line[i..], wd)) {
                    d = @intCast(wi);
                    break;
                }
            }
        }
        if (d) |v| {
            if (!found_first) {
                first = v;
                found_first = true;
            }
            last = v;
        }
    }
    return first * 10 + last;
}

pub fn main() !void {
    var t1: u32 = 0;
    var t2: u32 = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        t1 += calibration(line, false);
        t2 += calibration(line, true);
    }
    print("part 1: {d}\n", .{t1});
    print("part 2: {d}\n", .{t2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
