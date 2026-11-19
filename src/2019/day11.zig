const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;
const intcode = @import("intcode");

// const zom = @import("zom");

const data = @embedFile("data/day11.txt");

const P = [2]i32;

fn runRobot(start_color: u8) !Map(P, u8) {
    var vm = try intcode.VM.initSource(gpa, data);
    defer vm.deinit();
    try vm.addInput(start_color);

    var hull = Map(P, u8).init(gpa);
    errdefer hull.deinit();

    var pos: P = .{ 0, 0 };
    var dir: P = .{ 0, -1 }; // facing up

    var consumed: usize = 0;
    while (!vm.halted) {
        // feed current panel color if the VM wants input
        if (vm.in_head >= vm.inputs.items.len) {
            const here = hull.get(pos) orelse 0;
            try vm.addInput(here);
        }
        // run until we have 2 new outputs or halt
        while (!vm.halted and vm.outputs.items.len - consumed < 2) {
            _ = try vm.step();
        }
        if (vm.halted) break;
        const color: u8 = @intCast(vm.outputs.items[consumed]);
        const turn: u8 = @intCast(vm.outputs.items[consumed + 1]);
        consumed += 2;

        try hull.put(pos, color);
        // 0 = left 90°, 1 = right 90°
        const nd: P = if (turn == 0) .{ dir[1], -dir[0] } else .{ -dir[1], dir[0] };
        dir = nd;
        pos = .{ pos[0] + dir[0], pos[1] + dir[1] };
    }
    return hull;
}

pub fn main() !void {
    {
        var hull = try runRobot(0);
        defer hull.deinit();
        print("part 1: {d}\n", .{hull.count()});
    }
    {
        var hull = try runRobot(1);
        defer hull.deinit();
        // render
        var min_x: i32 = std.math.maxInt(i32);
        var max_x: i32 = std.math.minInt(i32);
        var min_y: i32 = std.math.maxInt(i32);
        var max_y: i32 = std.math.minInt(i32);
        var it = hull.keyIterator();
        while (it.next()) |k| {
            min_x = @min(min_x, k[0]);
            max_x = @max(max_x, k[0]);
            min_y = @min(min_y, k[1]);
            max_y = @max(max_y, k[1]);
        }
        print("part 2 ({d}x{d}):\n", .{ max_x - min_x + 1, max_y - min_y + 1 });
        var y = min_y;
        while (y <= max_y) : (y += 1) {
            var x = min_x;
            while (x <= max_x) : (x += 1) {
                const c = hull.get(.{ x, y }) orelse 0;
                print("{s}", .{if (c == 1) "#" else " "});
            }
            print("\n", .{});
        }
    }
}

// Useful stdlib functions

const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
