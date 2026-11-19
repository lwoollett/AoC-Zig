const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day14.txt");

fn knotHash(input: []const u8, out: *[16]u8) void {
    var lengths: [512]u8 = undefined;
    var n_len: usize = 0;
    for (input) |c| {
        lengths[n_len] = c;
        n_len += 1;
    }
    for ([_]u8{ 17, 31, 73, 47, 23 }) |c| {
        lengths[n_len] = c;
        n_len += 1;
    }
    var list: [256]u8 = undefined;
    for (&list, 0..) |*v, i| v.* = @intCast(i);
    var pos: usize = 0;
    var skip: usize = 0;
    var round: usize = 0;
    while (round < 64) : (round += 1) {
        for (lengths[0..n_len]) |len| {
            var a = pos;
            var b = (pos + @as(usize, len) - 1) % 256;
            var swaps = @as(usize, len) / 2;
            while (swaps > 0) : (swaps -= 1) {
                std.mem.swap(u8, &list[a], &list[b]);
                a = (a + 1) % 256;
                b = (b + 256 - 1) % 256;
            }
            pos = (pos + len + skip) % 256;
            skip += 1;
        }
    }
    for (0..16) |block| {
        var x: u8 = 0;
        for (0..16) |k| x ^= list[block * 16 + k];
        out[block] = x;
    }
}

const n = 128;
var grid: [n][n]bool = @splat(@splat(false));
var region: [n][n]u32 = @splat(@splat(0));

fn flood(x: usize, y: usize, id: u32) void {
    if (region[y][x] != 0 or !grid[y][x]) return;
    region[y][x] = id;
    if (x > 0) flood(x - 1, y, id);
    if (x + 1 < n) flood(x + 1, y, id);
    if (y > 0) flood(x, y - 1, id);
    if (y + 1 < n) flood(x, y + 1, id);
}

pub fn main() !void {
    const key = trim(u8, data, " \n\r\t");
    var row_key_buf: [256]u8 = undefined;

    var used: u32 = 0;
    for (0..n) |i| {
        const row_key = try std.fmt.bufPrint(&row_key_buf, "{s}-{d}", .{ key, i });
        var hash: [16]u8 = undefined;
        knotHash(row_key, &hash);
        for (hash, 0..) |b, byte| {
            for (0..8) |bit| {
                const on = (b >> @intCast(7 - bit)) & 1 == 1;
                grid[i][byte * 8 + bit] = on;
                if (on) used += 1;
            }
        }
    }
    print("part 1: {d}\n", .{used});

    var regions: u32 = 0;
    for (0..n) |y| {
        for (0..n) |x| {
            if (grid[y][x] and region[y][x] == 0) {
                regions += 1;
                flood(x, y, regions);
            }
        }
    }
    print("part 2: {d}\n", .{regions});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
