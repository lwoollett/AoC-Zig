const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day04.txt");

pub fn main() !void {
    // collect lines, sort (timestamps sort lexicographically)
    var lines_list: List([]const u8) = .empty;
    defer lines_list.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        try lines_list.append(gpa, line);
    }
    std.mem.sort([]const u8, lines_list.items, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.order(u8, a, b) == .lt;
        }
    }.lessThan);

    var sleep_total = Map(u32, u64).init(gpa);
    defer sleep_total.deinit();
    // guard -> [60]u32 minute counts
    var sleep_min = Map(u32, *[60]u32).init(gpa);
    defer {
        var it = sleep_min.valueIterator();
        while (it.next()) |m| gpa.free(m.*);
        sleep_min.deinit();
    }

    var cur_guard: u32 = 0;
    var asleep_since: u32 = 0;

    for (lines_list.items) |line| {
        // [1518-11-01 00:00] Guard #10 begins shift
        const bracket = std.mem.findScalar(u8, line, ']').?;
        const body = trim(u8, line[bracket + 1 ..], " ");
        const minute = try parseInt(u32, line[bracket - 2 .. bracket], 10);

        if (std.mem.find(u8, body, "Guard #") != null) {
            const hash = std.mem.findScalar(u8, body, '#').?;
            const rest = body[hash + 1 ..];
            const end = std.mem.findScalar(u8, rest, ' ') orelse rest.len;
            cur_guard = try parseInt(u32, rest[0..end], 10);
        } else if (std.mem.find(u8, body, "falls asleep") != null) {
            asleep_since = minute;
        } else if (std.mem.find(u8, body, "wakes up") != null) {
            const total = sleep_total.get(cur_guard) orelse 0;
            try sleep_total.put(cur_guard, total + (minute - asleep_since));
            const counts = sleep_min.get(cur_guard) orelse blk: {
                const c = try gpa.create([60]u32);
                c.* = @splat(0);
                try sleep_min.put(cur_guard, c);
                break :blk c;
            };
            for (asleep_since..minute) |m| {
                counts[m] += 1;
            }
        }
    }

    // part 1: sleepiest guard
    var best_guard: u32 = 0;
    var best_total: u64 = 0;
    var it = sleep_total.iterator();
    while (it.next()) |e| {
        if (e.value_ptr.* > best_total) {
            best_total = e.value_ptr.*;
            best_guard = e.key_ptr.*;
        }
    }
    const counts1 = sleep_min.get(best_guard).?;
    var best_min: usize = 0;
    for (counts1, 0..) |c, m| {
        if (c > counts1[best_min]) best_min = m;
    }
    print("part 1: {d}\n", .{best_guard * @as(u32, @intCast(best_min))});

    // part 2: most frequent (guard, minute)
    var bg: u32 = 0;
    var bm: usize = 0;
    var bc: u32 = 0;
    var it2 = sleep_min.iterator();
    while (it2.next()) |e| {
        for (e.value_ptr.*[0..], 0..) |c, m| {
            if (c > bc) {
                bc = c;
                bg = e.key_ptr.*;
                bm = m;
            }
        }
    }
    print("part 2: {d}\n", .{bg * @as(u32, @intCast(bm))});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
