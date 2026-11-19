const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day11.txt");

const P = [2]i64;

fn sumDistances(expansion: i64) !u64 {
    var gals: List(P) = .empty;
    defer gals.deinit(gpa);
    var row_has: List(bool) = .empty;
    defer row_has.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    var h: usize = 0;
    var w: usize = 0;
    while (lines.next()) |line| : (h += 1) {
        w = @max(w, line.len);
        for (line, 0..) |c, x| {
            if (c == '#') {
                try gals.append(gpa, .{ @intCast(x), @intCast(h) });
            }
        }
    }
    // rows with galaxies
    for (0..h) |_| try row_has.append(gpa, false);
    for (gals.items) |g| row_has.items[@intCast(g[1])] = true;

    var col_has = try gpa.alloc(bool, w);
    defer gpa.free(col_has);
    @memset(col_has, false);
    for (gals.items) |g| col_has[@intCast(g[0])] = true;

    // expanded coords
    for (gals.items) |*g| {
        var ex: i64 = 0;
        var x: usize = 0;
        while (x < @as(usize, @intCast(g[0]))) : (x += 1) {
            if (!col_has[x]) ex += expansion - 1;
        }
        var ey: i64 = 0;
        var y: usize = 0;
        while (y < @as(usize, @intCast(g[1]))) : (y += 1) {
            if (!row_has.items[y]) ey += expansion - 1;
        }
        g[0] += ex;
        g[1] += ey;
    }

    var total: u64 = 0;
    for (gals.items, 0..) |a, i| {
        for (gals.items[i + 1 ..]) |b| {
            total += @abs(a[0] - b[0]) + @abs(a[1] - b[1]);
        }
    }
    return total;
}

pub fn main() !void {
    print("part 1: {d}\n", .{try sumDistances(2)});
    print("part 2: {d}\n", .{try sumDistances(1_000_000)});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
