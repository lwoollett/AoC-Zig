const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day02.txt");

// Diamond keypad (part 2); part 1 is the plain 3x3.
const diamond = [_]struct { x: i32, y: i32, ch: u8 }{
    .{ .x = 2, .y = 0, .ch = '1' },
    .{ .x = 1, .y = 1, .ch = '2' },
    .{ .x = 2, .y = 1, .ch = '3' },
    .{ .x = 3, .y = 1, .ch = '4' },
    .{ .x = 0, .y = 2, .ch = '5' },
    .{ .x = 1, .y = 2, .ch = '6' },
    .{ .x = 2, .y = 2, .ch = '7' },
    .{ .x = 3, .y = 2, .ch = '8' },
    .{ .x = 4, .y = 2, .ch = '9' },
    .{ .x = 1, .y = 3, .ch = 'A' },
    .{ .x = 2, .y = 3, .ch = 'B' },
    .{ .x = 3, .y = 3, .ch = 'C' },
    .{ .x = 2, .y = 4, .ch = 'D' },
};

fn keyAt3(x: i32, y: i32) ?u8 {
    if (x >= -1 and x <= 1 and y >= -1 and y <= 1) {
        // part 1 keypad: 1..9
        return @intCast('1' + @as(u8, @intCast((y + 1) * 3 + (x + 1))));
    }
    return null;
}

fn keyAtD(x: i32, y: i32) ?u8 {
    for (diamond) |k| {
        if (k.x == x and k.y == y) return k.ch;
    }
    return null;
}

pub fn main() !void {
    var code1: [16]u8 = undefined;
    var code2: [16]u8 = undefined;
    var n1: usize = 0;
    var n2: usize = 0;

    // part 1 starts at '5' (0,0); part 2 at diamond '5' (0,2).
    var x1: i32 = 0;
    var y1: i32 = 0;
    var x2: i32 = 0;
    var y2: i32 = 2;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        for (line) |c| {
            const d = delta(c);
            if (keyAt3(x1 + d[0], y1 + d[1])) |_| {
                x1 += d[0];
                y1 += d[1];
            }
            if (keyAtD(x2 + d[0], y2 + d[1])) |_| {
                x2 += d[0];
                y2 += d[1];
            }
        }
        code1[n1] = keyAt3(x1, y1).?;
        n1 += 1;
        code2[n2] = keyAtD(x2, y2).?;
        n2 += 1;
    }

    print("part 1: {s}\n", .{code1[0..n1]});
    print("part 2: {s}\n", .{code2[0..n2]});
}

fn delta(c: u8) [2]i32 {
    return switch (c) {
        'U' => .{ 0, -1 },
        'D' => .{ 0, 1 },
        'L' => .{ -1, 0 },
        'R' => .{ 1, 0 },
        else => .{ 0, 0 },
    };
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
