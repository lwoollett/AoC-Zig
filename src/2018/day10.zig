const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day10.txt");

const Pt = struct { x: i64, y: i64, vx: i64, vy: i64 };

pub fn main() !void {
    var pts: List(Pt) = .empty;
    defer pts.deinit(gpa);
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // position=< 9,  1> velocity=< 0,  2>
        var nums: [4]i64 = undefined;
        var n: usize = 0;
        var it = tokenizeAny(u8, line, "position=<,>velocity ");
        _ = &it;
        var it2 = tokenizeAny(u8, line, " ,<>velocty=");
        while (it2.next()) |tok| {
            if (tok.len == 0) continue;
            if (n < 4) {
                nums[n] = parseInt(i64, tok, 10) catch continue;
                n += 1;
            }
        }
        try pts.append(gpa, .{ .x = nums[0], .y = nums[1], .vx = nums[2], .vy = nums[3] });
    }

    // advance while the bounding box shrinks
    var t: u64 = 0;
    var best_area: i64 = std.math.maxInt(i64);
    var best_t: u64 = 0;
    while (t < 100000) : (t += 1) {
        var min_x: i64 = std.math.maxInt(i64);
        var max_x: i64 = std.math.minInt(i64);
        var min_y: i64 = std.math.maxInt(i64);
        var max_y: i64 = std.math.minInt(i64);
        for (pts.items) |p| {
            const x = p.x + p.vx * @as(i64, @intCast(t));
            const y = p.y + p.vy * @as(i64, @intCast(t));
            min_x = @min(min_x, x);
            max_x = @max(max_x, x);
            min_y = @min(min_y, y);
            max_y = @max(max_y, y);
        }
        const area = (max_x - min_x) * (max_y - min_y);
        if (area < best_area) {
            best_area = area;
            best_t = t;
        } else if (t > best_t + 2) {
            break; // growing again
        }
    }

    // render at best_t
    var min_x: i64 = std.math.maxInt(i64);
    var max_x: i64 = std.math.minInt(i64);
    var min_y: i64 = std.math.maxInt(i64);
    var max_y: i64 = std.math.minInt(i64);
    for (pts.items) |p| {
        const x = p.x + p.vx * @as(i64, @intCast(best_t));
        const y = p.y + p.vy * @as(i64, @intCast(best_t));
        min_x = @min(min_x, x);
        max_x = @max(max_x, x);
        min_y = @min(min_y, y);
        max_y = @max(max_y, y);
    }

    print("part 1 (read the letters):\n", .{});
    var y = min_y;
    while (y <= max_y) : (y += 1) {
        var x = min_x;
        while (x <= max_x) : (x += 1) {
            var on = false;
            for (pts.items) |p| {
                if (p.x + p.vx * @as(i64, @intCast(best_t)) == x and p.y + p.vy * @as(i64, @intCast(best_t)) == y) {
                    on = true;
                    break;
                }
            }
            print("{s}", .{if (on) "#" else "."});
        }
        print("\n", .{});
    }
    print("part 2: {d}\n", .{best_t});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
