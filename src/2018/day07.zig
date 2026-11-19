const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day07.txt");

pub fn main() !void {
    var deps: [26]u32 = @splat(0); // deps[i] = bitmask of steps i depends on
    var present: u32 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "Step C must be finished before step A can begin."
        const a = line[5] - 'A';
        const b = line[36] - 'A';
        deps[b] |= @as(u32, 1) << @intCast(a);
        present |= @as(u32, 1) << @intCast(a);
        present |= @as(u32, 1) << @intCast(b);
    }
    const n_steps: u32 = @popCount(present);

    // Part 1: alphabetical topological order.
    {
        var done: u32 = 0;
        var order: [26]u8 = undefined;
        var count: usize = 0;
        while (count < n_steps) {
            var s: u5 = 0;
            while (s < 26) : (s += 1) {
                const bit = @as(u32, 1) << s;
                if (present & bit == 0) continue;
                if (done & bit != 0) continue;
                if (deps[s] & ~done == 0) {
                    done |= bit;
                    order[count] = @as(u8, 'A') + s;
                    count += 1;
                    s = 0; // restart from the smallest
                    if (count == n_steps) break;
                    continue;
                }
            }
        }
        print("part 1: {s}\n", .{order[0..count]});
    }

    // Part 2: 5 workers, 60 + index seconds per step.
    {
        var done: u32 = 0; // FINISHED steps (dependency gate)
        var claimed: u32 = 0; // finished OR in progress (no double-claim)
        var working: [5]?u8 = @splat(null);
        var remain: [5]u32 = @splat(0);
        var t: u32 = 0;
        var finished: u32 = 0;
        while (finished < n_steps) {
            // pick up new steps (alphabetical); dependencies must be FINISHED
            var s: u5 = 0;
            while (s < 26) : (s += 1) {
                const bit = @as(u32, 1) << s;
                if (present & bit == 0 or claimed & bit != 0) continue;
                if (deps[s] & ~done != 0) continue;
                // free worker?
                for (&working, 0..) |*wk, wi| {
                    if (wk.* == null) {
                        wk.* = @intCast(s);
                        remain[wi] = 61 + @as(u32, s);
                        claimed |= bit;
                        break;
                    }
                }
            }
            // advance one second
            for (&working, 0..) |*wk, wi| {
                if (wk.* != null) {
                    remain[wi] -= 1;
                    if (remain[wi] == 0) {
                        finished += 1;
                        const step = wk.*.?;
                        done |= @as(u32, 1) << @as(u5, @intCast(step));
                        wk.* = null;
                    }
                }
            }
            t += 1;
        }
        print("part 2: {d}\n", .{t});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
