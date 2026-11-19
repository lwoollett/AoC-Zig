const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day10.txt");

const P = struct { x: i64, y: i64 };

const gw = 40;
const gh = 40;

fn gcd(a: u64, b: u64) u64 {
    if (b == 0) return a;
    return gcd(b, @mod(a, b));
}

const Dir = struct { dx: i64, dy: i64 };

fn dirKey(d: Dir) i64 {
    return d.dx * 100_000 + d.dy;
}

pub fn main() !void {
    var grid: [gh][gw]u8 = @splat(@splat('.'));
    var w: usize = 0;
    var h: usize = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }

    var asteroids: List(P) = .empty;
    defer asteroids.deinit(gpa);
    for (0..h) |y| {
        for (0..w) |x| {
            if (grid[y][x] == '#') {
                try asteroids.append(gpa, .{ .x = @intCast(x), .y = @intCast(y) });
            }
        }
    }

    // part 1: max distinct directions
    var best_count: usize = 0;
    var station: P = .{ .x = 0, .y = 0 };
    for (asteroids.items) |a| {
        var dirs = Map(i64, void).init(gpa);
        defer dirs.deinit();
        for (asteroids.items) |b| {
            if (a.x == b.x and a.y == b.y) continue;
            var dx = b.x - a.x;
            var dy = b.y - a.y;
            const g = gcd(@abs(dx), @abs(dy));
            dx = @divTrunc(dx, @as(i64, @intCast(g)));
            dy = @divTrunc(dy, @as(i64, @intCast(g)));
            try dirs.put(dirKey(.{ .dx = dx, .dy = dy }), {});
        }
        if (dirs.count() > best_count) {
            best_count = dirs.count();
            station = a;
        }
    }
    print("part 1: {d}\n", .{best_count});

    // part 2: vaporize from the station, clockwise from up.
    // Group by direction; each direction's targets sorted by distance.
    const Group = struct { angle: f64, targets: List(P) };
    var groups: List(Group) = .empty;
    defer {
        for (groups.items) |*gr| gr.targets.deinit(gpa);
        groups.deinit(gpa);
    }

    for (asteroids.items) |b| {
        if (b.x == station.x and b.y == station.y) continue;
        const dx = b.x - station.x;
        const dy = b.y - station.y;
        const g = gcd(@abs(dx), @abs(dy));
        const ndx = @divTrunc(dx, @as(i64, @intCast(g)));
        const ndy = @divTrunc(dy, @as(i64, @intCast(g)));
        // angle clockwise from up: up=(0,-1) -> 0
        const angle = std.math.atan2(@as(f64, @floatFromInt(ndx)), @as(f64, @floatFromInt(-ndy)));
        const a2: f64 = if (angle < 0) angle + 2.0 * std.math.pi else angle;
        var found = false;
        for (groups.items) |*gr| {
            if (gr.targets.items.len > 0) {
                var gdx = gr.targets.items[0].x - station.x;
                var gdy = gr.targets.items[0].y - station.y;
                const gg = gcd(@abs(gdx), @abs(gdy));
                gdx = @divTrunc(gdx, @as(i64, @intCast(gg)));
                gdy = @divTrunc(gdy, @as(i64, @intCast(gg)));
                if (gdx == ndx and gdy == ndy) {
                    try gr.targets.append(gpa, b);
                    found = true;
                    break;
                }
            }
        }
        if (!found) {
            var targets: List(P) = .empty;
            try targets.append(gpa, b);
            try groups.append(gpa, .{ .angle = a2, .targets = targets });
        }
    }

    // sort groups by angle; targets within by distance
    std.mem.sort(Group, groups.items, {}, struct {
        fn lessThan(_: void, a: Group, b: Group) bool {
            return a.angle < b.angle;
        }
    }.lessThan);
    for (groups.items) |*gr| {
        std.mem.sort(P, gr.targets.items, station, struct {
            fn lessThan(st: P, a: P, b: P) bool {
                const da = (a.x - st.x) * (a.x - st.x) + (a.y - st.y) * (a.y - st.y);
                const db = (b.x - st.x) * (b.x - st.x) + (b.y - st.y) * (b.y - st.y);
                return da < db;
            }
        }.lessThan);
    }

    // vaporize
    var destroyed: usize = 0;
    var result: i64 = -1;
    outer: while (destroyed < 200) {
        for (groups.items) |*gr| {
            if (gr.targets.items.len == 0) continue;
            const victim = gr.targets.orderedRemove(0);
            destroyed += 1;
            if (destroyed == 200) {
                result = victim.x * 100 + victim.y;
                break :outer;
            }
        }
    }
    print("part 2: {d}\n", .{result});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;
const sort = std.sort.block;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
