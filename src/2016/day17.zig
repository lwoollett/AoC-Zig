const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day17.txt");

const Md5 = std.crypto.hash.Md5;
const Pos = struct { x: u2, y: u2, path: []const u8 };

fn doorOpen(digit: u8) bool {
    return digit >= 'b'; // b..f open
}

pub fn main() !void {
    const passcode = trim(u8, data, " \n\r\t");

    // BFS over (position, path); door state derives from md5(passcode ++ path).
    var queue: List(Pos) = .empty;
    defer {
        for (queue.items) |p| gpa.free(p.path);
        queue.deinit(gpa);
    }
    try queue.append(gpa, .{ .x = 0, .y = 0, .path = try gpa.dupe(u8, "") });

    var shortest: ?[]u8 = null;
    var longest: usize = 0;

    var qi: usize = 0;
    while (qi < queue.items.len) : (qi += 1) {
        const cur = queue.items[qi];
        if (cur.x == 3 and cur.y == 3) {
            if (shortest == null) {
                shortest = try gpa.dupe(u8, cur.path);
            }
            longest = @max(longest, cur.path.len);
            continue; // vault reached: path ends
        }

        var buf: [1024]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "{s}{s}", .{ passcode, cur.path }) catch unreachable;
        var digest: [16]u8 = undefined;
        Md5.hash(msg, &digest, .{});
        const nib = [4]u8{
            digest[0] >> 4, digest[0] & 0x0f,
            digest[1] >> 4, digest[1] & 0x0f,
        };
        const hex = "0123456789abcdef";
        // order: U, D, L, R
        const moves = [4]struct { ch: u8, dx: i8, dy: i8 }{
            .{ .ch = 'U', .dx = 0, .dy = -1 },
            .{ .ch = 'D', .dx = 0, .dy = 1 },
            .{ .ch = 'L', .dx = -1, .dy = 0 },
            .{ .ch = 'R', .dx = 1, .dy = 0 },
        };
        for (moves, 0..) |m, i| {
            if (!doorOpen(hex[nib[i]])) continue;
            const nx = @as(i16, cur.x) + m.dx;
            const ny = @as(i16, cur.y) + m.dy;
            if (nx < 0 or ny < 0 or nx > 3 or ny > 3) continue;
            const path = try std.mem.concat(gpa, u8, &.{ cur.path, &[1]u8{m.ch} });
            try queue.append(gpa, .{ .x = @intCast(nx), .y = @intCast(ny), .path = path });
        }
    }

    if (shortest) |s| {
        print("part 1: {s}\n", .{s});
    }
    print("part 2: {d}\n", .{longest});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
