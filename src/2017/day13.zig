const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day13.txt");

const max_layers = 100;

var depth: [max_layers]u32 = @splat(0);
var range: [max_layers]u32 = @splat(0);
var n_layers: usize = 0;

fn caught(delay: u64) bool {
    for (depth[0..n_layers], range[0..n_layers]) |d, r| {
        const period = 2 * (@as(u64, r) - 1);
        if ((delay + d) % period == 0) return true;
    }
    return false;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const colon = std.mem.findScalar(u8, line, ':').?;
        depth[n_layers] = try parseInt(u32, line[0..colon], 10);
        range[n_layers] = try parseInt(u32, trim(u8, line[colon + 1 ..], " \r"), 10);
        n_layers += 1;
    }

    var severity: u64 = 0;
    for (depth[0..n_layers], range[0..n_layers]) |d, r| {
        const period = 2 * (@as(u64, r) - 1);
        if (d % period == 0) severity += @as(u64, d) * r;
    }
    print("part 1: {d}\n", .{severity});

    var delay: u64 = 0;
    while (caught(delay)) delay += 1;
    print("part 2: {d}\n", .{delay});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
