const std = @import("std");
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day06.txt");

pub fn main() !void {
    var banks: List(u32) = .empty;
    defer banks.deinit(gpa);
    var it = tokenizeAny(u8, data, " \t\n");
    while (it.next()) |tok| {
        try banks.append(gpa, try parseInt(u32, tok, 10));
    }
    const n = banks.items.len;

    var seen = StrMap(u64).init(gpa);
    defer seen.deinit();

    var steps: u64 = 0;
    var first_seen: u64 = 0;
    while (true) {
        var buf: [512]u8 = undefined;
        var fbs = std.Io.Writer.fixed(&buf);
        for (banks.items, 0..) |b, i| {
            if (i > 0) fbs.writeByte(' ') catch {};
            fbs.print("{d}", .{b}) catch {};
        }
        const key = fbs.buffer[0..fbs.end];
        if (seen.get(key)) |at| {
            first_seen = at;
            break;
        }
        try seen.put(try gpa.dupe(u8, key), steps);

        // redistribute the largest bank
        var mi: usize = 0;
        for (banks.items, 0..) |b, i| {
            if (b > banks.items[mi]) mi = i;
        }
        var blocks = banks.items[mi];
        banks.items[mi] = 0;
        var idx = mi;
        while (blocks > 0) : (blocks -= 1) {
            idx = (idx + 1) % n;
            banks.items[idx] += 1;
        }
        steps += 1;
    }

    print("part 1: {d}\n", .{steps});
    print("part 2: {d}\n", .{steps - first_seen});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
