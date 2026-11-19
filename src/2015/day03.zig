const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day03.txt");

fn housesMovedBy(moves: []const u8, start: usize, step: usize, visited: *Map([2]i32, void)) !void {
    var x: i32 = 0;
    var y: i32 = 0;
    var i = start;
    while (i < moves.len) : (i += step) {
        switch (moves[i]) {
            '^' => y += 1,
            'v' => y -= 1,
            '>' => x += 1,
            '<' => x -= 1,
            else => {},
        }
        try visited.put(.{ x, y }, {});
    }
}

pub fn main() !void {
    // Part 1: one santa.
    {
        var visited = Map([2]i32, void).init(gpa);
        defer visited.deinit();
        try visited.put(.{ 0, 0 }, {});
        try housesMovedBy(data, 0, 1, &visited);
        print("part 1: {d}\n", .{visited.count()});
    }
    // Part 2: santa + robo-santa alternate moves.
    {
        var visited = Map([2]i32, void).init(gpa);
        defer visited.deinit();
        try visited.put(.{ 0, 0 }, {});
        try housesMovedBy(data, 0, 2, &visited);
        try housesMovedBy(data, 1, 2, &visited);
        print("part 2: {d}\n", .{visited.count()});
    }
}

// Useful stdlib functions

const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
