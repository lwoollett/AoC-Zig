const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day18.txt");

const Entry = struct { depth: u8, value: u64 };

fn parse(line: []const u8, out: *List(Entry)) !void {
    var depth: u8 = 0;
    for (line) |c| {
        switch (c) {
            '[' => depth += 1,
            ']' => depth -= 1,
            ',' => {},
            else => {
                try out.append(gpa, .{ .depth = depth - 1, .value = c - '0' });
            },
        }
    }
}

fn explode(entries: *List(Entry)) bool {
    for (entries.items, 0..) |e, i| {
        if (e.depth >= 5 and i + 1 < entries.items.len and entries.items[i + 1].depth == e.depth) {
            // explode pair at i, i+1
            const a = entries.items[i].value;
            const b = entries.items[i + 1].value;
            if (i > 0) entries.items[i - 1].value += a;
            if (i + 2 < entries.items.len) entries.items[i + 2].value += b;
            entries.items[i] = .{ .depth = e.depth - 1, .value = 0 };
            _ = entries.orderedRemove(i + 1);
            return true;
        }
    }
    return false;
}

fn split(entries: *List(Entry)) bool {
    for (entries.items, 0..) |e, i| {
        if (e.value >= 10) {
            const lo = e.value / 2;
            const hi = e.value - lo;
            entries.items[i] = .{ .depth = e.depth + 1, .value = lo };
            entries.insert(gpa, i + 1, .{ .depth = e.depth + 1, .value = hi }) catch return false;
            return true;
        }
    }
    return false;
}

fn reduce(entries: *List(Entry)) void {
    while (true) {
        if (explode(entries)) continue;
        if (split(entries)) continue;
        break;
    }
}

fn magnitude(entries: []const Entry) u64 {
    var work = List(Entry).empty;
    defer work.deinit(gpa);
    for (entries) |e| {
        work.append(gpa, e) catch unreachable;
    }
    while (work.items.len > 1) {
        // find max depth
        var max_d: u8 = 0;
        for (work.items) |e| max_d = @max(max_d, e.depth);
        // find adjacent pair at max depth
        var i: usize = 0;
        while (i + 1 < work.items.len) : (i += 1) {
            if (work.items[i].depth == max_d and work.items[i + 1].depth == max_d) break;
        }
        const combined = 3 * work.items[i].value + 2 * work.items[i + 1].value;
        work.items[i] = .{ .depth = max_d -| 1, .value = combined };
        _ = work.orderedRemove(i + 1);
    }
    return work.items[0].value;
}

pub fn main() !void {
    var lines: List([]const u8) = .empty;
    defer lines.deinit(gpa);
    var it = tokenizeAny(u8, data, "\n");
    while (it.next()) |line| {
        try lines.append(gpa, line);
    }

    // part 1: sum all
    var acc = List(Entry).empty;
    defer acc.deinit(gpa);
    try parse(lines.items[0], &acc);
    for (lines.items[1..]) |line| {
        var next = List(Entry).empty;
        defer next.deinit(gpa);
        try parse(line, &next);
        // merge: all depths + 1
        for (acc.items) |*e| e.depth += 1;
        for (next.items) |*e| e.depth += 1;
        try acc.appendSlice(gpa, next.items);
        reduce(&acc);
    }
    print("part 1: {d}\n", .{magnitude(acc.items)});

    // part 2: max magnitude of any pair sum
    var best: u64 = 0;
    for (lines.items, 0..) |la, i| {
        for (lines.items, 0..) |lb, j| {
            if (i == j) continue;
            var sum = List(Entry).empty;
            defer sum.deinit(gpa);
            try parse(la, &sum);
            var nb = List(Entry).empty;
            defer nb.deinit(gpa);
            try parse(lb, &nb);
            for (sum.items) |*e| e.depth += 1;
            for (nb.items) |*e| e.depth += 1;
            try sum.appendSlice(gpa, nb.items);
            reduce(&sum);
            best = @max(best, magnitude(sum.items));
        }
    }
    print("part 2: {d}\n", .{best});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
