const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day08.txt");

var nums: List(u32) = .empty;
var pos: usize = 0;

// One recursive pass: each node yields (metadata total, node value).
fn readNode2() struct { total: u64, value: u64 } {
    const n_children = nums.items[pos];
    pos += 1;
    const n_meta = nums.items[pos];
    pos += 1;

    var children: List(u64) = .empty;
    defer children.deinit(gpa);
    var total: u64 = 0;
    for (0..n_children) |_| {
        const r = readNode2();
        total += r.total;
        children.append(gpa, r.value) catch unreachable;
    }
    var meta_total: u64 = 0;
    var value: u64 = 0;
    for (0..n_meta) |_| {
        const m = nums.items[pos];
        pos += 1;
        meta_total += m;
        if (n_children == 0) {
            value += m;
        } else if (m >= 1 and m <= children.items.len) {
            value += children.items[m - 1];
        }
    }
    return .{ .total = total + meta_total, .value = value };
}

pub fn main() !void {
    var it = tokenizeAny(u8, data, " \n\r\t");
    while (it.next()) |tok| {
        try nums.append(gpa, try parseInt(u32, tok, 10));
    }
    pos = 0;
    const root = readNode2();
    print("part 1: {d}\n", .{root.total});
    print("part 2: {d}\n", .{root.value});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
