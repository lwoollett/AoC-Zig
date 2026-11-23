const std = @import("std");
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day08.txt");

const Node = struct { l: []const u8, r: []const u8 };

var nodes = StrMap(Node).init(std.heap.page_allocator);

fn stepsTo(start: []const u8, target_suffix: u8, instr: []const u8) u64 {
    var cur = start;
    var i: usize = 0;
    var steps: u64 = 0;
    while (true) {
        if (target_suffix == 0) {
            if (std.mem.eql(u8, cur, "ZZZ")) return steps;
        } else {
            if (cur[2] == target_suffix) return steps;
        }
        const n = nodes.get(cur).?;
        cur = if (instr[i] == 'L') n.l else n.r;
        i = (i + 1) % instr.len;
        steps += 1;
    }
}

fn gcd(a: u64, b: u64) u64 {
    if (b == 0) return a;
    return gcd(b, a % b);
}

pub fn main() !void {
    var lines = splitSca(u8, data, '\n');
    const instr = trim(u8, lines.next().?, " \r");

    var starts: List([]const u8) = .empty;
    defer starts.deinit(gpa);
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) continue;
        // "AAA = (BBB, CCC)"
        const key = try std.heap.page_allocator.dupe(u8, line[0..3]);
        const l = try std.heap.page_allocator.dupe(u8, line[7..10]);
        const r = try std.heap.page_allocator.dupe(u8, line[12..15]);
        try nodes.put(key, .{ .l = l, .r = r });
        if (key[2] == 'A') {
            try starts.append(gpa, key);
        }
    }

    print("part 1: {d}\n", .{stepsTo("AAA", 0, instr)});

    var lcm: u64 = 1;
    for (starts.items) |s| {
        const t = stepsTo(s, 'Z', instr);
        lcm = lcm / gcd(lcm, t) * t;
    }
    print("part 2: {d}\n", .{lcm});
}

// Useful stdlib functions
const splitSca = std.mem.splitScalar;
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
