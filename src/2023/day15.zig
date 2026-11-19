const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day15.txt");

fn hashStr(s: []const u8) u64 {
    var v: u64 = 0;
    for (s) |c| {
        v = (v + c) * 17 % 256;
    }
    return v;
}

const Lens = struct { label: []const u8, focal: u64 };

pub fn main() !void {
    var total1: u64 = 0;
    var total2: u64 = 0;

    var boxes: [256]List(Lens) = @splat(.empty);

    var it = tokenizeSca(u8, trim(u8, data, " \n\r\t"), ',');
    while (it.next()) |step_raw| {
        const step = trim(u8, step_raw, " ");
        total1 += hashStr(step);

        // op: '-' removes; '=' inserts/updates
        if (std.mem.indexOfScalar(u8, step, '-')) |dash| {
            const label = step[0..dash];
            const b = hashStr(label);
            for (boxes[@intCast(b)].items, 0..) |lens, i| {
                if (std.mem.eql(u8, lens.label, label)) {
                    _ = boxes[@intCast(b)].orderedRemove(i);
                    break;
                }
            }
        } else {
            const eq = indexOf(u8, step, '=').?;
            const label = step[0..eq];
            const focal = try parseInt(u64, step[eq + 1 ..], 10);
            const b = hashStr(label);
            var found = false;
            for (boxes[@intCast(b)].items) |*lens| {
                if (std.mem.eql(u8, lens.label, label)) {
                    lens.focal = focal;
                    found = true;
                    break;
                }
            }
            if (!found) {
                try boxes[@intCast(b)].append(gpa, .{ .label = label, .focal = focal });
            }
        }
    }

    for (boxes, 0..) |box, bi| {
        for (box.items, 0..) |lens, li| {
            total2 += (bi + 1) * (li + 1) * lens.focal;
        }
    }
    print("part 1: {d}\n", .{total1});
    print("part 2: {d}\n", .{total2});
}

// Useful stdlib functions
const tokenizeSca = std.mem.tokenizeScalar;
const indexOf = std.mem.findScalar;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
