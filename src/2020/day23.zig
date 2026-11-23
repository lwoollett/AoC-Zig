const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day23.txt");

pub fn main() !void {
    var cups9: [9]u32 = undefined;
    for (trim(u8, data, " \n\r\t"), 0..) |c, i| {
        cups9[i] = c - '0';
    }

    // part 1: 100 moves on 9 cups (array rotation)
    {
        var cups = cups9;
        var cur: usize = 0;
        var move: usize = 0;
        while (move < 100) : (move += 1) {
            // pick up 3 cups clockwise from current
            var picked: [3]u32 = undefined;
            var remain: [6]u32 = undefined;
            var rn: usize = 0;
            for (0..8) |k| {
                const src = (cur + 1 + k) % 9;
                if (k < 3) {
                    picked[k] = cups[src];
                } else {
                    remain[rn] = cups[src];
                    rn += 1;
                }
            }
            // current cup stays at front of remain? — rebuild: current first
            var order: [9]u32 = undefined;
            order[0] = cups[cur];
            for (0..rn) |k| order[1 + k] = remain[k];

            // destination: current label -1 (wrap over picked)
            const cur_label = order[0];
            var dest = cur_label;
            while (true) {
                if (dest == 1) dest = 9 else dest -= 1;
                var is_picked = false;
                for (picked) |p| {
                    if (p == dest) is_picked = true;
                }
                if (!is_picked) break;
            }
            // find dest index in the valid prefix of order
            const olen = 1 + rn;
            var di: usize = 0;
            for (order[0..olen], 0..) |v, k| {
                if (v == dest) di = k;
            }
            // place picked right after dest, then everything else
            var next: [9]u32 = undefined;
            var nn: usize = 0;
            for (order[0..olen], 0..) |v, k| {
                next[nn] = v;
                nn += 1;
                if (k == di) {
                    for (picked) |p| {
                        next[nn] = p;
                        nn += 1;
                    }
                }
            }
            cups = next;
            // advance current
            for (cups, 0..) |v, k| {
                if (v == cur_label) cur = (k + 1) % 9;
            }
        }
        // read from cup 1
        var one_i: usize = 0;
        for (cups, 0..) |v, k| {
            if (v == 1) one_i = k;
        }
        print("part 1: ", .{});
        var k: usize = 1;
        while (k < 9) : (k += 1) {
            print("{d}", .{cups[(one_i + k) % 9]});
        }
        print("\n", .{});
    }

    // part 2: 1M cups, 10M moves — circular linked list via next[]
    {
        const n: u32 = 1_000_000;
        var next = try gpa.alloc(u32, n + 1);
        defer gpa.free(next);
        for (1..n) |v| {
            next[v] = @intCast(v + 1);
        }
        // wire the initial 9
        for (0..8) |k| {
            next[cups9[k]] = cups9[k + 1];
        }
        next[cups9[8]] = 10;
        next[n] = cups9[0]; // close the circle

        var cur = cups9[0];
        var move: usize = 0;
        while (move < 10_000_000) : (move += 1) {
            const p1 = next[cur];
            const p2 = next[p1];
            const p3 = next[p2];
            const after = next[p3];

            var dest: u32 = if (cur == 1) n else cur - 1;
            while (dest == p1 or dest == p2 or dest == p3) {
                dest = if (dest == 1) n else dest - 1;
            }

            // remove picked, insert after dest
            next[cur] = after;
            next[p3] = next[dest];
            next[dest] = p1;

            cur = after;
        }
        const a = next[1];
        const b = next[a];
        print("part 2: {d}\n", .{@as(u64, a) * b});
    }
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
