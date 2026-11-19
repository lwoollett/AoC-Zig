const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day25.txt");

const max_pts = 2000;

const Pt = struct { x: i32, y: i32, z: i32, t: i32 };

fn dist(a: Pt, b: Pt) u32 {
    return @as(u32, @intCast(@abs(a.x - b.x))) + @as(u32, @intCast(@abs(a.y - b.y))) +
        @as(u32, @intCast(@abs(a.z - b.z))) + @as(u32, @intCast(@abs(a.t - b.t)));
}

var parent: [max_pts]usize = undefined;

fn find(x: usize) usize {
    if (parent[x] == x) return x;
    parent[x] = find(parent[x]);
    return parent[x];
}

fn merge(a: usize, b: usize) void {
    const ra = find(a);
    const rb = find(b);
    if (ra != rb) parent[ra] = rb;
}

pub fn main() !void {
    var pts: [max_pts]Pt = undefined;
    var n: usize = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, ",");
        pts[n] = .{
            .x = try parseInt(i32, it.next().?, 10),
            .y = try parseInt(i32, it.next().?, 10),
            .z = try parseInt(i32, it.next().?, 10),
            .t = try parseInt(i32, it.next().?, 10),
        };
        n += 1;
    }

    for (0..n) |i| parent[i] = i;
    for (0..n) |i| {
        for (i + 1..n) |j| {
            if (dist(pts[i], pts[j]) <= 3) merge(i, j);
        }
    }

    var roots = Map(usize, void).init(gpa);
    defer roots.deinit();
    for (0..n) |i| {
        try roots.put(find(i), {});
    }

    print("part 1: {d}\n", .{roots.count()});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
