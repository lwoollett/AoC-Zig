const std = @import("std");
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day04.txt");

pub fn main() !void {
    var valid1: u32 = 0;
    var valid2: u32 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var seen1 = StrMap(void).init(gpa);
        defer seen1.deinit();
        var seen2 = Map(u64, void).init(gpa);
        defer seen2.deinit();

        var ok1 = true;
        var ok2 = true;
        var it = tokenizeAny(u8, line, " ");
        while (it.next()) |word| {
            if (seen1.contains(word)) ok1 = false;
            try seen1.put(word, {});
            // anagram signature: hash of the sorted letters
            const buf = try gpa.dupe(u8, word);
            defer gpa.free(buf);
            std.mem.sort(u8, buf, {}, comptime std.sort.asc(u8));
            const sig = std.hash.Wyhash.hash(0, buf);
            if (seen2.contains(sig)) ok2 = false;
            try seen2.put(sig, {});
        }
        if (ok1) valid1 += 1;
        if (ok2) valid2 += 1;
    }

    print("part 1: {d}\n", .{valid1});
    print("part 2: {d}\n", .{valid2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;
const sort = std.sort.block;
const asc = std.sort.asc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
