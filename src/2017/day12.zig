const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day12.txt");

const max_progs = 3000;

pub fn main() !void {
    var connected: [max_progs][32]u16 = @splat(@splat(0));
    var n_conn: [max_progs]u8 = @splat(0);
    var max_id: usize = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "0 <-> 2" / "2 <-> 0, 3, 4"
        const arrow = std.mem.find(u8, line, "<->").?;
        const id = try parseInt(u16, trim(u8, line[0..arrow], " "), 10);
        max_id = @max(max_id, id);
        var it = tokenizeAny(u8, line[arrow + 3 ..], ", ");
        while (it.next()) |tok| {
            const other = try parseInt(u16, tok, 10);
            max_id = @max(max_id, other);
            connected[id][n_conn[id]] = other;
            n_conn[id] += 1;
        }
    }

    // groups via BFS coloring
    var group: [max_progs]u16 = @splat(0); // 0 = unvisited
    var n_groups: u16 = 0;
    var queue: List(u16) = .empty;
    defer queue.deinit(gpa);

    var start: usize = 0;
    while (start <= max_id) : (start += 1) {
        if (group[start] != 0) continue;
        n_groups += 1;
        try queue.append(gpa, @intCast(start));
        group[start] = n_groups;
        var qi: usize = 0;
        while (qi < queue.items.len) : (qi += 1) {
            const cur = queue.items[qi];
            for (connected[cur][0..n_conn[cur]]) |nb| {
                if (group[nb] == 0) {
                    group[nb] = n_groups;
                    try queue.append(gpa, nb);
                }
            }
        }
        if (start == 0) {
            var count: usize = 0;
            for (group[0 .. max_id + 1]) |g| {
                if (g == 1) count += 1;
            }
            print("part 1: {d}\n", .{count});
        }
        queue.clearRetainingCapacity();
    }

    print("part 2: {d}\n", .{n_groups});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.findScalar;
const indexOfAny = std.mem.findAny;
const indexOfStr = std.mem.findPos;
const lastIndexOf = std.mem.findScalarLast;
const lastIndexOfAny = std.mem.findLastAny;
const lastIndexOfStr = std.mem.findLastLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
