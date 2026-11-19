const std = @import("std");
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day13.txt");

const max_people = 10;

var happy: [max_people][max_people]i64 = @splat(@splat(0));
var n_people: usize = 0;

var best: i64 = std.math.minInt(i64);

fn seat(path: *[max_people]usize, used: *[max_people]bool, depth: usize, sum: i64) void {
    if (depth == n_people) {
        // Circular table: close the loop.
        var total = sum;
        total += happy[path[depth - 1]][path[0]];
        total += happy[path[0]][path[depth - 1]];
        best = @max(best, total);
        return;
    }
    var c: usize = 0;
    while (c < n_people) : (c += 1) {
        if (used[c]) continue;
        used[c] = true;
        path[depth] = c;
        var extra: i64 = 0;
        if (depth > 0) {
            extra += happy[path[depth - 1]][c];
            extra += happy[c][path[depth - 1]];
        }
        seat(path, used, depth + 1, sum + extra);
        used[c] = false;
    }
}

fn personId(ids: *StrMap(usize), name: []const u8) !usize {
    if (ids.get(name)) |id| return id;
    const id = n_people;
    n_people += 1;
    try ids.put(name, id);
    return id;
}

fn solve() i64 {
    var path: [max_people]usize = undefined;
    var used: [max_people]bool = @splat(false);
    best = std.math.minInt(i64);
    seat(&path, &used, 0, 0);
    return best;
}

pub fn main() !void {
    var ids = StrMap(usize).init(gpa);
    defer ids.deinit();

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "Alice would gain 54 happiness units by sitting next to Bob."
        var it = tokenizeAny(u8, line, " ");
        const who = it.next().?;
        _ = it.next().?; // would
        const dirword = it.next().?; // gain | lose
        const amount = try parseInt(i64, it.next().?, 10);
        _ = it.next().?; // happiness
        _ = it.next().?; // units
        _ = it.next().?; // by
        _ = it.next().?; // sitting
        _ = it.next().?; // next
        _ = it.next().?; // to
        var next = it.next().?;
        next = trim(u8, next, ".");

        const delta: i64 = if (std.mem.eql(u8, dirword, "gain")) amount else -amount;
        const a = try personId(&ids, who);
        const b = try personId(&ids, next);
        happy[a][b] = delta;
    }

    print("part 1: {d}\n", .{solve()});

    // Part 2: add yourself — neutral happiness with everyone.
    n_people += 1; // new person index n_people-1, zero matrix rows/cols = neutral
    print("part 2: {d}\n", .{solve()});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
