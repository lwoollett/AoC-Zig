const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day05.txt");

var before = Map(u32, List(u32)).init(std.heap.page_allocator);

fn correctlyOrdered(update: []const u32) bool {
    for (update, 0..) |page, i| {
        for (update[i + 1 ..]) |later| {
            // later must not come before page
            if (before.get(later)) |list| {
                for (list.items) |b| {
                    if (b == page) return false;
                }
            }
        }
    }
    return true;
}

fn orderKey(ctx: u32, a: u32, b: u32) bool {
    // true if a < b (a must come before b)
    if (before.get(a)) |list| {
        for (list.items) |x| {
            if (x == b) return true;
        }
    }
    _ = ctx;
    return false;
}

pub fn main() !void {
    var total1: u64 = 0;
    var total2: u64 = 0;

    var lines = splitSca(u8, data, '\n');
    var in_updates = false;
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) {
            in_updates = true;
            continue;
        }
        if (!in_updates) {
            const pipe = indexOf(u8, line, '|').?;
            const a = try parseInt(u32, line[0..pipe], 10);
            const b = try parseInt(u32, line[pipe + 1 ..], 10);
            const gop = try before.getOrPut(a);
            if (!gop.found_existing) gop.value_ptr.* = .empty;
            try gop.value_ptr.append(std.heap.page_allocator, b);
        } else {
            var nums: List(u32) = .empty;
            defer nums.deinit(gpa);
            var it = tokenizeSca(u8, line, ',');
            while (it.next()) |tok| {
                try nums.append(gpa, try parseInt(u32, tok, 10));
            }
            if (correctlyOrdered(nums.items)) {
                total1 += nums.items[nums.items.len / 2];
            } else {
                // insertion sort with the order relation
                var arr = nums.items;
                var i: usize = 1;
                while (i < arr.len) : (i += 1) {
                    var j = i;
                    while (j > 0 and orderKey(0, arr[j], arr[j - 1])) : (j -= 1) {
                        const tmp = arr[j];
                        arr[j] = arr[j - 1];
                        arr[j - 1] = tmp;
                    }
                }
                total2 += arr[arr.len / 2];
            }
        }
    }
    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{total2});
}

// Useful stdlib functions
const tokenizeSca = std.mem.tokenizeScalar;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.findScalar;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
