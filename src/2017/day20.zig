const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day20.txt");

const Particle = struct {
    p: [3]i64,
    v: [3]i64,
    a: [3]i64,
    alive: bool = true,
};

pub fn main() !void {
    var particles: List(Particle) = .empty;
    defer particles.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // p=<x,y,z>, v=<...>, a=<...>
        var nums: [9]i64 = undefined;
        var n: usize = 0;
        var it = tokenizeAny(u8, line, "pva=<,> ");
        while (it.next()) |tok| {
            if (tok.len == 0) continue;
            nums[n] = try parseInt(i64, tok, 10);
            n += 1;
        }
        try particles.append(gpa, .{
            .p = .{ nums[0], nums[1], nums[2] },
            .v = .{ nums[3], nums[4], nums[5] },
            .a = .{ nums[6], nums[7], nums[8] },
        });
    }

    // Part 1: smallest acceleration (Manhattan), tie-break smallest velocity/pos.
    var best: usize = 0;
    var best_acc: u64 = std.math.maxInt(u64);
    var best_v: u64 = std.math.maxInt(u64);
    for (particles.items, 0..) |pt, i| {
        const acc = @abs(pt.a[0]) + @abs(pt.a[1]) + @abs(pt.a[2]);
        const vel = @abs(pt.v[0]) + @abs(pt.v[1]) + @abs(pt.v[2]);
        if (acc < best_acc or (acc == best_acc and vel < best_v)) {
            best_acc = acc;
            best_v = vel;
            best = i;
        }
    }
    print("part 1: {d}\n", .{best});

    // Part 2: remove collisions each tick.
    var tick: u32 = 0;
    while (tick < 1000) : (tick += 1) {
        for (particles.items) |*pt| {
            if (!pt.alive) continue;
            for (0..3) |k| {
                pt.v[k] += pt.a[k];
                pt.p[k] += pt.v[k];
            }
        }
        // mark collisions
        for (particles.items, 0..) |*a, i| {
            if (!a.alive) continue;
            for (particles.items[i + 1 ..]) |*b| {
                if (!b.alive) continue;
                if (std.mem.eql(i64, &a.p, &b.p)) {
                    a.alive = false;
                    b.alive = false;
                }
            }
        }
    }
    var alive: usize = 0;
    for (particles.items) |pt| {
        if (pt.alive) alive += 1;
    }
    print("part 2: {d}\n", .{alive});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
