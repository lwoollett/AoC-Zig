const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day23.txt");

var names = StrMap(usize).init(std.heap.page_allocator);
var name_list: List([]const u8) = .empty;
var adj: List(Map(usize, void)) = .empty;

var best_clique: List(usize) = .empty;

fn bronKerbosch(r: []const usize, p: *List(usize), x: *List(usize)) !void {
    if (p.items.len == 0 and x.items.len == 0) {
        if (r.len > best_clique.items.len) {
            best_clique.clearRetainingCapacity();
            try best_clique.appendSlice(gpa, r);
        }
        return;
    }
    // iterate a snapshot; remove v from P and add to X as we go
    var snapshot = List(usize).empty;
    defer snapshot.deinit(gpa);
    try snapshot.appendSlice(gpa, p.items);
    for (snapshot.items) |v| {
        if (!contains(p.*, v)) continue; // already moved to X
        // R + v
        var r2 = try gpa.alloc(usize, r.len + 1);
        defer gpa.free(r2);
        @memcpy(r2[0..r.len], r);
        r2[r.len] = v;

        // P ∩ N(v), X ∩ N(v)
        var p2: List(usize) = .empty;
        defer p2.deinit(gpa);
        for (p.items) |u| {
            if (adj.items[v].contains(u)) {
                try p2.append(gpa, u);
            }
        }
        var x2: List(usize) = .empty;
        defer x2.deinit(gpa);
        for (x.items) |u| {
            if (adj.items[v].contains(u)) {
                try x2.append(gpa, u);
            }
        }
        try bronKerbosch(r2, &p2, &x2);

        // move v: P -> X
        removeByValue(p, v);
        try x.append(gpa, v);
    }
}

fn contains(list: List(usize), v: usize) bool {
    for (list.items) |u| {
        if (u == v) return true;
    }
    return false;
}

fn removeByValue(list: *List(usize), v: usize) void {
    for (list.items, 0..) |u, i| {
        if (u == v) {
            _ = list.orderedRemove(i);
            return;
        }
    }
}

/// Simpler iterative max-clique via pivot-free recursion with explicit removal
fn maxClique() !void {
    var all: List(usize) = .empty;
    var empty_x: List(usize) = .empty;
    defer all.deinit(gpa);
    for (0..adj.items.len) |i| {
        try all.append(gpa, i);
    }
    try bronKerbosch(&.{}, &all, &empty_x);
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const dash = indexOf(u8, line, '-').?;
        const a_name = try std.heap.page_allocator.dupe(u8, line[0..dash]);
        const b_name = try std.heap.page_allocator.dupe(u8, line[dash + 1 ..]);
        const a = try nodeName(a_name);
        const b = try nodeName(b_name);
        try adj.items[a].put(b, {});
        try adj.items[b].put(a, {});
    }
    const n = adj.items.len;

    // part 1: triangles with at least one 't' name
    var tri: u64 = 0;
    for (0..n) |a| {
        for (a + 1..n) |b| {
            if (!adj.items[a].contains(b)) continue;
            for (b + 1..n) |c| {
                if (!adj.items[a].contains(c) or !adj.items[b].contains(c)) continue;
                if (name_list.items[a][0] == 't' or name_list.items[b][0] == 't' or name_list.items[c][0] == 't') {
                    tri += 1;
                }
            }
        }
    }
    print("part 1: {d}\n", .{tri});

    // part 2: max clique
    try maxClique();
    var members: List([]const u8) = .empty;
    defer members.deinit(gpa);
    for (best_clique.items) |i| {
        try members.append(gpa, name_list.items[i]);
    }
    std.mem.sort([]const u8, members.items, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.order(u8, a, b) == .lt;
        }
    }.lessThan);
    print("part 2: ", .{});
    for (members.items, 0..) |m, i| {
        if (i > 0) print(",", .{});
        print("{s}", .{m});
    }
    print("\n", .{});
}

fn nodeName(name: []const u8) !usize {
    const gop = try names.getOrPut(name);
    if (!gop.found_existing) {
        gop.value_ptr.* = name_list.items.len;
        try name_list.append(gpa, name);
        try adj.append(gpa, Map(usize, void).init(gpa));
    }
    return gop.value_ptr.*;
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
