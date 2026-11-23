const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day11.txt");

fn increment(pw: []u8) void {
    var i = pw.len - 1;
    while (true) {
        if (i == 0 and pw[i] == 'z') @panic("overflow");
        pw[i] += 1;
        if (pw[i] > 'z') {
            pw[i] = 'a';
            i -= 1;
            continue;
        }
        // Skip forbidden characters entirely.
        if (pw[i] == 'i' or pw[i] == 'o' or pw[i] == 'l') pw[i] += 1;
        break;
    }
}

fn hasStraight(pw: []const u8) bool {
    var i: usize = 0;
    while (i + 2 < pw.len) : (i += 1) {
        if (pw[i + 1] == pw[i] + 1 and pw[i + 2] == pw[i] + 2) return true;
    }
    return false;
}

fn hasTwoPairs(pw: []const u8) bool {
    var pairs: usize = 0;
    var i: usize = 0;
    while (i + 1 < pw.len) : (i += 1) {
        if (pw[i] == pw[i + 1]) {
            pairs += 1;
            i += 1; // pairs must not overlap
        }
    }
    return pairs >= 2;
}

fn valid(pw: []const u8) bool {
    return hasStraight(pw) and hasTwoPairs(pw);
}

pub fn main() !void {
    var pw: [16]u8 = undefined;
    const start = trim(u8, data, " \n\r\t");
    @memcpy(pw[0..start.len], start);
    const p = pw[0..start.len];

    increment(p); // Santa's next password must be strictly after the current one
    while (!valid(p)) increment(p);
    print("part 1: {s}\n", .{p});

    increment(p);
    while (!valid(p)) increment(p);
    print("part 2: {s}\n", .{p});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
