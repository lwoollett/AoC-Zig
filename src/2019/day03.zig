const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day03.txt");

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    const wire1 = lines.next().?;
    const wire2 = lines.next().?;

    // position -> first time this wire touched it
    var seen1 = Map([2]i32, i32).init(gpa);
    defer seen1.deinit();
    var seen2 = Map([2]i32, i32).init(gpa);
    defer seen2.deinit();

    try trace(wire1, &seen1);
    try trace(wire2, &seen2);

    var best_manhattan: i32 = std.math.maxInt(i32);
    var best_steps: i32 = std.math.maxInt(i32);

    var it = seen1.iterator();
    while (it.next()) |e| {
        if (seen2.get(e.key_ptr.*)) |steps2| {
            const m = @abs(e.key_ptr.*[0]) + @abs(e.key_ptr.*[1]);
            best_manhattan = @min(best_manhattan, m);
            best_steps = @min(best_steps, e.value_ptr.* + steps2);
        }
    }

    print("part 1: {d}\n", .{best_manhattan});
    print("part 2: {d}\n", .{best_steps});
}

fn trace(path: []const u8, seen: *Map([2]i32, i32)) !void {
    var x: i32 = 0;
    var y: i32 = 0;
    var steps: i32 = 0;
    var it = tokenizeAny(u8, path, ",");
    while (it.next()) |seg| {
        const dir = seg[0];
        const count = try parseInt(i32, seg[1..], 10);
        var dx: i32 = 0;
        var dy: i32 = 0;
        switch (dir) {
            'U' => dy = 1,
            'D' => dy = -1,
            'L' => dx = -1,
            'R' => dx = 1,
            else => {},
        }
        var i: i32 = 0;
        while (i < count) : (i += 1) {
            x += dx;
            y += dy;
            steps += 1;
            const key = [2]i32{ x, y };
            if (!seen.contains(key)) {
                try seen.put(key, steps);
            }
        }
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
