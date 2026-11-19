const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day22.txt");

const max_nodes = 1200;
const Node = struct { x: u32, y: u32, size: u64, used: u64, avail: u64 };

pub fn main() !void {
    var nodes: [max_nodes]Node = undefined;
    var n: usize = 0;
    var max_x: u32 = 0;
    var max_y: u32 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (!startsWith(line, "/dev/grid/node-x")) continue;
        var it = tokenizeAny(u8, line, " \t");
        const name = it.next().?;
        // /dev/grid/node-x0-y0
        const xdash = std.mem.findScalar(u8, name, 'x').?;
        const ydash = std.mem.findScalar(u8, name, 'y').?;
        const x = try parseInt(u32, name[xdash + 1 .. ydash - 1], 10);
        const y = try parseInt(u32, name[ydash + 1 ..], 10);
        const size = try parseInt(u64, trim(u8, it.next().?, "T"), 10);
        const used = try parseInt(u64, trim(u8, it.next().?, "T"), 10);
        const avail = try parseInt(u64, trim(u8, it.next().?, "T"), 10);
        nodes[n] = .{ .x = x, .y = y, .size = size, .used = used, .avail = avail };
        n += 1;
        max_x = @max(max_x, x);
        max_y = @max(max_y, y);
    }

    // Part 1: viable pairs.
    var viable: u64 = 0;
    for (nodes[0..n]) |a| {
        if (a.used == 0) continue;
        for (nodes[0..n]) |b| {
            if (a.x == b.x and a.y == b.y) continue;
            if (b.avail >= a.used) viable += 1;
        }
    }
    print("part 1: {d}\n", .{viable});

    // Part 2: BFS over (hole position, payload position).
    const w = max_x + 1;
    const h = max_y + 1;
    const idx = struct {
        fn f(ww: u32, x: u32, y: u32) usize {
            return y * ww + x;
        }
    }.f;

    // Walls: nodes whose data can never be moved into any single empty node.
    var max_avail: u64 = 0;
    for (nodes[0..n]) |nd| max_avail = @max(max_avail, nd.avail);
    var passable = try gpa.alloc(bool, w * h);
    defer gpa.free(passable);
    for (passable) |*p| p.* = true;
    for (nodes[0..n]) |nd| {
        if (nd.used > max_avail) passable[idx(w, nd.x, nd.y)] = false;
    }

    var hole: usize = 0;
    for (nodes[0..n]) |nd| {
        if (nd.used == 0) {
            hole = idx(w, nd.x, nd.y);
            break;
        }
    }
    const payload_start = idx(w, max_x, 0); // goal data sits at top-right
    const goal = idx(w, 0, 0);

    var dist = try gpa.alloc(i32, w * h * w * h);
    defer gpa.free(dist);
    @memset(dist, -1);

    var queue: List([2]usize) = .empty;
    defer queue.deinit(gpa);
    try queue.append(gpa, .{ hole, payload_start });
    dist[hole * (w * h) + payload_start] = 0;

    var qi: usize = 0;
    var answer: i32 = -1;
    while (qi < queue.items.len) : (qi += 1) {
        const cur = queue.items[qi];
        const cur_hole = cur[0];
        const cur_payload = cur[1];
        const d = dist[cur_hole * (w * h) + cur_payload];
        if (cur_payload == goal) {
            answer = d;
            break;
        }
        const hx = cur_hole % w;
        const hy = cur_hole / w;
        const moves = [4][2]i32{ .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 }, .{ 0, -1 } };
        for (moves) |m| {
            const nx = @as(i64, @intCast(hx)) + m[0];
            const ny = @as(i64, @intCast(hy)) + m[1];
            if (nx < 0 or ny < 0 or nx >= w or ny >= h) continue;
            const npos: usize = @intCast(ny * @as(i64, w) + nx);
            if (!passable[npos]) continue;
            // hole moves to npos; if npos held the payload, payload swaps to old hole
            const new_payload: usize = if (npos == cur_payload) cur_hole else cur_payload;
            const key = npos * (w * h) + new_payload;
            if (dist[key] != -1) continue;
            dist[key] = d + 1;
            try queue.append(gpa, .{ npos, new_payload });
        }
    }

    print("part 2: {d}\n", .{answer});
}

fn startsWith(s: []const u8, prefix: []const u8) bool {
    return std.mem.startsWith(u8, s, prefix);
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
