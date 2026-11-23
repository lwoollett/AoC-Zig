const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day14.txt");

const Robot = struct { px: i64, py: i64, vx: i64, vy: i64 };

const w = 101;
const h = 103;

pub fn main() !void {
    var robots: List(Robot) = .empty;
    defer robots.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, "p=,v ");
        const px = try parseInt(i64, it.next().?, 10);
        const py = try parseInt(i64, it.next().?, 10);
        const vx = try parseInt(i64, it.next().?, 10);
        const vy = try parseInt(i64, it.next().?, 10);
        try robots.append(gpa, .{ .px = px, .py = py, .vx = vx, .vy = vy });
    }

    // part 1: after 100 seconds
    {
        var q = [4]u64{ 0, 0, 0, 0 };
        for (robots.items) |r| {
            const x = @mod(r.px + r.vx * 100, w);
            const y = @mod(r.py + r.vy * 100, h);
            if (x == w / 2 or y == h / 2) continue;
            const qx: usize = if (x < w / 2) 0 else 1;
            const qy: usize = if (y < h / 2) 0 else 1;
            q[qy * 2 + qx] += 1;
        }
        print("part 1: {d}\n", .{q[0] * q[1] * q[2] * q[3]});
    }

    // part 2: find the frame where robots form the christmas tree. The
    // cluster-count heuristic ties between non-tree frames, so score every
    // frame by its largest 4-connected blob — the tree is the only frame
    // with a big one. A full period (w*h) covers every distinct frame.
    {
        var best_t: u64 = 0;
        var best_blob: usize = 0;
        const occ = try gpa.alloc(bool, w * h);
        defer gpa.free(occ);
        const label = try gpa.alloc(u32, w * h);
        defer gpa.free(label);
        var stack: List(u32) = .empty;
        defer stack.deinit(gpa);
        var t: u64 = 0;
        while (t < w * h) : (t += 1) {
            @memset(occ, false);
            for (robots.items) |r| {
                const x = @mod(r.px + r.vx * @as(i64, @intCast(t)), w);
                const y = @mod(r.py + r.vy * @as(i64, @intCast(t)), h);
                occ[@intCast(y * w + x)] = true;
            }
            @memset(label, 0);
            var lbl: u32 = 0;
            var largest: usize = 0;
            for (0..w * h) |i| {
                if (!occ[i] or label[i] != 0) continue;
                lbl += 1;
                var size: usize = 0;
                stack.clearRetainingCapacity();
                label[i] = lbl;
                try stack.append(gpa, @intCast(i));
                while (stack.pop()) |c| {
                    size += 1;
                    const cx = c % w;
                    if (cx > 0 and occ[c - 1] and label[c - 1] == 0) {
                        label[c - 1] = lbl;
                        try stack.append(gpa, c - 1);
                    }
                    if (cx + 1 < w and occ[c + 1] and label[c + 1] == 0) {
                        label[c + 1] = lbl;
                        try stack.append(gpa, c + 1);
                    }
                    if (c >= w and occ[c - w] and label[c - w] == 0) {
                        label[c - w] = lbl;
                        try stack.append(gpa, c - w);
                    }
                    if (c + w < w * h and occ[c + w] and label[c + w] == 0) {
                        label[c + w] = lbl;
                        try stack.append(gpa, c + w);
                    }
                }
                largest = @max(largest, size);
            }
            if (largest > best_blob) {
                best_blob = largest;
                best_t = t;
            }
        }
        print("part 2: {d}\n", .{best_t});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
