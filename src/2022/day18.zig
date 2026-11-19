const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day18.txt");

const P = [3]i32;

var cubes = Map(P, void).init(std.heap.page_allocator);

fn neighbors(p: P) [6]P {
    return .{
        .{ p[0] + 1, p[1], p[2] },
        .{ p[0] - 1, p[1], p[2] },
        .{ p[0], p[1] + 1, p[2] },
        .{ p[0], p[1] - 1, p[2] },
        .{ p[0], p[1], p[2] + 1 },
        .{ p[0], p[1], p[2] - 1 },
    };
}

pub fn main() !void {
    {
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            var it = tokenizeSca(u8, line, ',');
            const x = try parseInt(i32, it.next().?, 10);
            const y = try parseInt(i32, it.next().?, 10);
            const z = try parseInt(i32, it.next().?, 10);
            try cubes.put(.{ x, y, z }, {});
        }
    }

    // part 1: total exposed faces
    var faces: u64 = 0;
    var cit = cubes.keyIterator();
    while (cit.next()) |c| {
        for (neighbors(c.*)) |n| {
            if (!cubes.contains(n)) faces += 1;
        }
    }
    print("part 1: {d}\n", .{faces});

    // part 2: exterior only — flood fill air from outside a bounding box
    var lo: P = .{ std.math.maxInt(i32), std.math.maxInt(i32), std.math.maxInt(i32) };
    var hi: P = .{ std.math.minInt(i32), std.math.minInt(i32), std.math.minInt(i32) };
    var it2 = cubes.keyIterator();
    while (it2.next()) |c| {
        for (0..3) |i| {
            lo[i] = @min(lo[i], c[i] - 1);
            hi[i] = @max(hi[i], c[i] + 1);
        }
    }
    var outside = Map(P, void).init(gpa);
    defer outside.deinit();
    var q: List(P) = .empty;
    defer q.deinit(gpa);
    try outside.put(lo, {});
    try q.append(gpa, lo);
    var head: usize = 0;
    while (head < q.items.len) : (head += 1) {
        const cur = q.items[head];
        for (neighbors(cur)) |n| {
            var inside_box = true;
            for (0..3) |i| {
                if (n[i] < lo[i] or n[i] > hi[i]) inside_box = false;
            }
            if (!inside_box) continue;
            if (cubes.contains(n)) continue;
            if (outside.contains(n)) continue;
            try outside.put(n, {});
            try q.append(gpa, n);
        }
    }

    var ext_faces: u64 = 0;
    var it3 = cubes.keyIterator();
    while (it3.next()) |c| {
        for (neighbors(c.*)) |n| {
            if (outside.contains(n)) ext_faces += 1;
        }
    }
    print("part 2: {d}\n", .{ext_faces});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSca = std.mem.tokenizeScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
