const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day02.txt");

fn invalidExactlyTwo(id: u64) bool {
    var buf: [24]u8 = undefined;
    const s = std.fmt.bufPrint(&buf, "{d}", .{id}) catch return false;
    if (s.len % 2 != 0) return false;
    const half = s.len / 2;
    return std.mem.eql(u8, s[0..half], s[half..]);
}

fn invalidAtLeastTwo(id: u64) bool {
    var buf: [24]u8 = undefined;
    const s = std.fmt.bufPrint(&buf, "{d}", .{id}) catch return false;
    // some block of length k repeated at least twice: k divides len, k < len
    var k: usize = 1;
    while (k * 2 <= s.len) : (k += 1) {
        if (s.len % k != 0) continue;
        const block = s[0..k];
        var ok = true;
        var i: usize = k;
        while (i < s.len) : (i += k) {
            if (!std.mem.eql(u8, block, s[i .. i + k])) ok = false;
        }
        if (ok) return true;
    }
    return false;
}

pub fn main() !void {
    var total1: u64 = 0;
    var total2: u64 = 0;

    var it = tokenizeSca(u8, trim(u8, data, " \n\r\t"), ',');
    while (it.next()) |range| {
        const dash = indexOf(u8, range, '-').?;
        const lo = try parseInt(u64, range[0..dash], 10);
        const hi = try parseInt(u64, range[dash + 1 ..], 10);
        var v = lo;
        while (v <= hi) : (v += 1) {
            if (invalidExactlyTwo(v)) total1 += v;
            if (invalidAtLeastTwo(v)) total2 += v;
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
