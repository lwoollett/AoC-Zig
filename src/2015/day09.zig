const std = @import("std");
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day09.txt");

const max_cities = 10;

var dist: [max_cities][max_cities]u32 = @splat(@splat(0));
var n_cities: usize = 0;

var best_min: u64 = std.math.maxInt(u64);
var best_max: u64 = 0;

fn permute(path: *[max_cities]usize, used: *[max_cities]bool, depth: usize, len: u64) void {
    if (depth == n_cities) {
        best_min = @min(best_min, len);
        best_max = @max(best_max, len);
        return;
    }
    var c: usize = 0;
    while (c < n_cities) : (c += 1) {
        if (used[c]) continue;
        used[c] = true;
        path[depth] = c;
        const extra: u64 = if (depth == 0) 0 else dist[path[depth - 1]][c];
        permute(path, used, depth + 1, len + extra);
        used[c] = false;
    }
}

pub fn main() !void {
    var ids = StrMap(usize).init(gpa);
    defer ids.deinit();

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "A to B = N"
        var it = tokenizeAny(u8, line, " ");
        const a = it.next().?;
        _ = it.next().?; // "to"
        const b = it.next().?;
        _ = it.next().?; // "="
        const d = try parseInt(u32, it.next().?, 10);

        const ia = try cityId(&ids, a);
        const ib = try cityId(&ids, b);
        dist[ia][ib] = d;
        dist[ib][ia] = d;
    }

    var path: [max_cities]usize = undefined;
    var used: [max_cities]bool = @splat(false);
    permute(&path, &used, 0, 0);

    print("part 1: {d}\n", .{best_min});
    print("part 2: {d}\n", .{best_max});
}

fn cityId(ids: *StrMap(usize), name: []const u8) !usize {
    if (ids.get(name)) |id| return id;
    const id = n_cities;
    n_cities += 1;
    try ids.put(name, id);
    return id;
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
