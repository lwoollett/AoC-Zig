const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;
const intcode = @import("intcode");

// const zom = @import("zom");

const data = @embedFile("data/day15.txt");

const P = [2]i32;

// direction encoding: 1=N, 2=S, 3=W, 4=E
const moves = [4]i64{ 1, 2, 3, 4 };
const deltas = [4]P{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };
const opposite = [4]usize{ 1, 0, 3, 2 };

var vm: intcode.VM = undefined;
var maze = Map(P, u8).init(std.heap.page_allocator);

fn tryMove(dir: usize) !u8 {
    // returns status: 0 wall, 1 open, 2 oxygen
    try vm.addInput(moves[dir]);
    const before = vm.outputCount();
    while (!vm.halted and vm.outputCount() == before) {
        _ = try vm.step();
    }
    return @intCast(vm.lastOutput());
}

fn explore(pos: P) !void {
    for (0..4) |d| {
        const np: P = .{ pos[0] + deltas[d][0], pos[1] + deltas[d][1] };
        if (maze.contains(np)) continue;
        const status = try tryMove(d);
        if (status == 0) {
            try maze.put(np, '#');
        } else {
            try maze.put(np, if (status == 2) 'O' else '.');
            try explore(np);
            // backtrack
            _ = try tryMove(opposite[d]);
        }
    }
}

fn bfs(from: P) !Map(P, u32) {
    // NOTE: caller owns the returned map (deinit at call site).
    var dist = Map(P, u32).init(gpa);
    var q: List(P) = .empty;
    defer q.deinit(gpa);
    try dist.put(from, 0);
    try q.append(gpa, from);
    var head: usize = 0;
    while (head < q.items.len) {
        const cur = q.items[head];
        head += 1;
        const d0 = dist.get(cur).?;
        for (deltas) |dl| {
            const np: P = .{ cur[0] + dl[0], cur[1] + dl[1] };
            const cell = maze.get(np) orelse '#';
            if (cell == '#') continue;
            if (dist.contains(np)) continue;
            try dist.put(np, d0 + 1);
            try q.append(gpa, np);
        }
    }
    return dist;
}

pub fn main() !void {
    vm = try intcode.VM.initSource(gpa, data);
    defer vm.deinit();
    defer maze.deinit();

    const start: P = .{ 0, 0 };
    try maze.put(start, '.');
    try explore(start);

    // find oxygen
    var oxygen: P = start;
    var it = maze.iterator();
    while (it.next()) |e| {
        if (e.value_ptr.* == 'O') oxygen = e.key_ptr.*;
    }

    // part 1: BFS from start
    var dist_start = try bfs(start);
    defer dist_start.deinit();
    print("part 1: {d}\n", .{dist_start.get(oxygen).?});

    // part 2: fill time from oxygen
    var dist_o2 = try bfs(oxygen);
    defer dist_o2.deinit();
    var maxd: u32 = 0;
    var it2 = dist_o2.iterator();
    while (it2.next()) |e| {
        if (e.value_ptr.* > maxd) maxd = e.value_ptr.*;
    }
    print("part 2: {d}\n", .{maxd});
}

// Useful stdlib functions

const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
