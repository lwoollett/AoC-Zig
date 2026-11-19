const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day08.txt");

const w = 50;
const h = 6;
var screen: [h][w]bool = @splat(@splat(false));

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (startsWith(line, "rect ")) {
            // rect AxB
            var it = tokenizeAny(u8, line["rect ".len..], "x");
            const a = try parseInt(u32, it.next().?, 10);
            const b = try parseInt(u32, it.next().?, 10);
            for (0..b) |y| {
                for (0..a) |x| {
                    screen[y][x] = true;
                }
            }
        } else if (startsWith(line, "rotate row y=")) {
            var it = tokenizeAny(u8, line["rotate row y=".len..], " by");
            const y = try parseInt(usize, it.next().?, 10);
            const shift = try parseInt(usize, trim(u8, it.next().?, " "), 10);
            const row = screen[y];
            var new_row: [w]bool = @splat(false);
            for (row, 0..) |on, x| {
                if (on) new_row[(x + shift) % w] = true;
            }
            screen[y] = new_row;
        } else if (startsWith(line, "rotate column x=")) {
            var it = tokenizeAny(u8, line["rotate column x=".len..], " by");
            const x = try parseInt(usize, it.next().?, 10);
            const shift = try parseInt(usize, trim(u8, it.next().?, " "), 10);
            var col: [h]bool = undefined;
            for (0..h) |y| col[y] = screen[y][x];
            for (0..h) |y| {
                screen[y][x] = col[(y + h - shift % h) % h];
            }
        }
    }

    var lit: usize = 0;
    for (screen) |row| {
        for (row) |on| {
            if (on) lit += 1;
        }
    }
    print("part 1: {d}\n", .{lit});
    print("part 2 (read the letters):\n", .{});
    for (screen) |row| {
        for (row) |on| {
            print("{s}", .{if (on) "#" else "."});
        }
        print("\n", .{});
    }
}

fn startsWith(s: []const u8, prefix: []const u8) bool {
    return std.mem.startsWith(u8, s, prefix);
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
