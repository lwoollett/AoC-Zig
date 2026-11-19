const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day16.txt");

fn expandAndChecksum(seed: []const u8, disk_len: usize, buffer: []u8) []u8 {
    // build the dragon curve
    @memcpy(buffer[0..seed.len], seed);
    var len = seed.len;
    while (len < disk_len) {
        // buffer[len] = '0', then reversed+inverted copy of buffer[0..len]
        buffer[len] = '0';
        var i: usize = 0;
        while (i < len) : (i += 1) {
            const src = buffer[len - 1 - i];
            buffer[len + 1 + i] = if (src == '0') '1' else '0';
        }
        len = len * 2 + 1;
    }

    // checksum on the first disk_len chars
    var check_len = disk_len;
    while (check_len % 2 == 0) {
        var i: usize = 0;
        while (i < check_len / 2) : (i += 1) {
            buffer[i] = if (buffer[i * 2] == buffer[i * 2 + 1]) '1' else '0';
        }
        check_len /= 2;
    }
    return buffer[0..check_len];
}

pub fn main() !void {
    const seed = trim(u8, data, " \n\r\t");

    var buf1: [100_000]u8 = undefined;
    print("part 1: {s}\n", .{expandAndChecksum(seed, 272, &buf1)});

    const buf2 = try gpa.alloc(u8, 40_000_000);
    defer gpa.free(buf2);
    print("part 2: {s}\n", .{expandAndChecksum(seed, 35_651_584, buf2)});
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
