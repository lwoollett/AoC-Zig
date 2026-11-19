const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day18.txt");

const gs = 71;

var bytes: List([2]usize) = .empty;

fn connected(n_bytes: usize) bool {
    var corrupted = Map([2]usize, void).init(gpa);
    defer corrupted.deinit();
    for (bytes.items[0..n_bytes]) |b| {
        corrupted.put(b, {}) catch return false;
    }
    var visited = Map([2]usize, void).init(gpa);
    defer visited.deinit();
    var q: List([2]usize) = .empty;
    defer q.deinit(gpa);
    q.append(gpa, .{ 0, 0 }) catch return false;
    visited.put(.{ 0, 0 }, {}) catch return false;
    var head: usize = 0;
    while (head < q.items.len) : (head += 1) {
        const cur = q.items[head];
        if (cur[0] == gs - 1 and cur[1] == gs - 1) return true;
        const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
        for (deltas) |d| {
            const nx = @as(i32, @intCast(cur[0])) + d[0];
            const ny = @as(i32, @intCast(cur[1])) + d[1];
            if (nx < 0 or ny < 0 or nx >= gs or ny >= gs) continue;
            const key = [2]usize{ @intCast(nx), @intCast(ny) };
            if (corrupted.contains(key) or visited.contains(key)) continue;
            visited.put(key, {}) catch return false;
            q.append(gpa, key) catch return false;
        }
    }
    return false;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const comma = indexOf(u8, line, ',').?;
        const x = try parseInt(usize, line[0..comma], 10);
        const y = try parseInt(usize, line[comma + 1 ..], 10);
        try bytes.append(gpa, .{ x, y });
    }

    // part 1: after 1024 bytes, min steps (BFS distance)
    {
        var corrupted = Map([2]usize, void).init(gpa);
        defer corrupted.deinit();
        for (bytes.items[0..1024]) |b| {
            try corrupted.put(b, {});
        }
        var dist = Map([2]usize, u32).init(gpa);
        defer dist.deinit();
        var q: List([2]usize) = .empty;
        defer q.deinit(gpa);
        try dist.put(.{ 0, 0 }, 0);
        try q.append(gpa, .{ 0, 0 });
        var head: usize = 0;
        var answer: ?u32 = null;
        while (head < q.items.len) : (head += 1) {
            const cur = q.items[head];
            if (cur[0] == gs - 1 and cur[1] == gs - 1) {
                answer = dist.get(cur).?;
                break;
            }
            const deltas = [4][2]i32{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
            for (deltas) |d| {
                const nx = @as(i32, @intCast(cur[0])) + d[0];
                const ny = @as(i32, @intCast(cur[1])) + d[1];
                if (nx < 0 or ny < 0 or nx >= gs or ny >= gs) continue;
                const key = [2]usize{ @intCast(nx), @intCast(ny) };
                if (corrupted.contains(key) or dist.contains(key)) continue;
                try dist.put(key, dist.get(cur).? + 1);
                try q.append(gpa, key);
            }
        }
        if (answer) |a| {
            print("part 1: {d}\n", .{a});
        } else {
            print("part 1: blocked\n", .{});
        }
    }

    // part 2: binary search the first blocking byte
    {
        var lo: usize = 1;
        var hi: usize = bytes.items.len;
        // invariant: connected(lo-? ) — find smallest n where NOT connected(n)
        while (lo < hi) {
            const mid = lo + (hi - lo) / 2;
            if (connected(mid)) {
                lo = mid + 1;
            } else {
                hi = mid;
            }
        }
        const b = bytes.items[lo - 1];
        print("part 2: {d},{d}\n", .{ b[0], b[1] });
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
