const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day11.txt");

pub fn main() !void {
    var stones = Map(u128, u128).init(gpa);
    defer stones.deinit();
    var it = tokenizeAny(u8, trim(u8, data, " \n\r\t"), " ");
    while (it.next()) |tok| {
        const v = try parseInt(u128, tok, 10);
        const gop = try stones.getOrPut(v);
        if (!gop.found_existing) gop.value_ptr.* = 0;
        gop.value_ptr.* += 1;
    }

    var p1: u128 = 0;
    for (0..75) |blink| {
        var next = Map(u128, u128).init(gpa);
        var sit = stones.iterator();
        while (sit.next()) |e| {
            const v = e.key_ptr.*;
            const n = e.value_ptr.*;
            if (v == 0) {
                const gop = try next.getOrPut(1);
                if (!gop.found_existing) gop.value_ptr.* = 0;
                gop.value_ptr.* += n;
            } else {
                var digits: u64 = 0;
                var t = v;
                while (t > 0) : (t /= 10) digits += 1;
                if (digits % 2 == 0) {
                    var div: u64 = 1;
                    for (0..digits / 2) |_| div *= 10;
                    const left = v / div;
                    const right = v % div;
                    const g1 = try next.getOrPut(left);
                    if (!g1.found_existing) g1.value_ptr.* = 0;
                    g1.value_ptr.* += n;
                    const g2 = try next.getOrPut(right);
                    if (!g2.found_existing) g2.value_ptr.* = 0;
                    g2.value_ptr.* += n;
                } else {
                    const gop = try next.getOrPut(v * 2024);
                    if (!gop.found_existing) gop.value_ptr.* = 0;
                    gop.value_ptr.* += n;
                }
            }
        }
        stones.deinit();
        stones = next;
        if (blink == 24) {
            var total: u128 = 0;
            var vit = stones.valueIterator();
            while (vit.next()) |c| total += c.*;
            p1 = total;
        }
    }
    var p2: u128 = 0;
    var vit = stones.valueIterator();
    while (vit.next()) |c| p2 += c.*;

    print("part 1: {d}\n", .{p1});
    print("part 2: {d}\n", .{p2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
