const std = @import("std");
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day12.txt");

var adj = StrMap(*List([]const u8)).init(std.heap.page_allocator);
var visited = StrMap(u32).init(std.heap.page_allocator);
var path_count: u64 = 0;
var allow_twice = false;

fn isSmall(cave: []const u8) bool {
    return cave[0] >= 'a' and cave[0] <= 'z';
}

fn explore(cave: []const u8, twice_used: bool) anyerror!void {
    if (std.mem.eql(u8, cave, "end")) {
        path_count += 1;
        return;
    }
    if (isSmall(cave)) {
        const gop = try visited.getOrPut(cave);
        if (!gop.found_existing) gop.value_ptr.* = 0;
        if (gop.value_ptr.* >= 1) {
            if (!allow_twice or twice_used or std.mem.eql(u8, cave, "start")) {
                // not allowed — undo and bail
                return;
            }
        }
        gop.value_ptr.* += 1;
    }
    const visited_this = isSmall(cave);
    var now_twice = twice_used;
    if (visited_this and (visited.get(cave).? > 1)) now_twice = true;

    if (adj.get(cave)) |neighbors| {
        for (neighbors.items) |nb| {
            try explore(nb, now_twice);
        }
    }
    if (visited_this) {
        visited.getPtr(cave).?.* -= 1;
    }
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const dash = indexOf(u8, line, '-').?;
        const a = line[0..dash];
        const b = line[dash + 1 ..];
        const ga = try adj.getOrPut(a);
        if (!ga.found_existing) {
            const l = try std.heap.page_allocator.create(List([]const u8));
            l.* = .empty;
            ga.value_ptr.* = l;
        }
        try ga.value_ptr.*.append(std.heap.page_allocator, b);
        const gb = try adj.getOrPut(b);
        if (!gb.found_existing) {
            const l = try std.heap.page_allocator.create(List([]const u8));
            l.* = .empty;
            gb.value_ptr.* = l;
        }
        try gb.value_ptr.*.append(std.heap.page_allocator, a);
    }

    allow_twice = false;
    try explore("start", false);
    print("part 1: {d}\n", .{path_count});

    path_count = 0;
    visited.clearRetainingCapacity();
    allow_twice = true;
    try explore("start", false);
    print("part 2: {d}\n", .{path_count});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
