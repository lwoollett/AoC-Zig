const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day05.txt");

const Md5 = std.crypto.hash.Md5;

fn hexNibble(b: u8) u8 {
    return if (b < 10) '0' + b else 'a' + b - 10;
}

pub fn main() !void {
    const door = trim(u8, data, " \n\r\t");

    var password: [8]u8 = @splat('_');
    var found: u8 = 0;
    var p2: [8]u8 = @splat('_');
    var p2_found: u32 = 0;
    var p2_done = false;

    var index: u64 = 0;
    while (found < 8 or !p2_done) : (index += 1) {
        var buf: [64]u8 = undefined;
        const msg = try std.fmt.bufPrint(&buf, "{s}{d}", .{ door, index });
        var digest: [Md5.digest_length]u8 = undefined;
        Md5.hash(msg, &digest, .{});
        // five leading zero hex digits
        if (digest[0] != 0 or digest[1] != 0 or digest[2] > 0x0f) continue;

        const sixth = hexNibble(digest[2] & 0x0f);
        const seventh = digest[3] >> 4;

        if (found < 8) {
            password[found] = sixth;
            found += 1;
        }
        if (!p2_done and sixth >= '0' and sixth <= '7') {
            const pos: usize = sixth - '0';
            if (p2[pos] == '_') {
                p2[pos] = hexNibble(seventh);
                p2_found += 1;
                if (p2_found == 8) p2_done = true;
            }
        }
    }

    print("part 1: {s}\n", .{password});
    print("part 2: {s}\n", .{p2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.findScalar;
const indexOfAny = std.mem.findAny;
const indexOfStr = std.mem.findPos;
const lastIndexOf = std.mem.findScalarLast;
const lastIndexOfAny = std.mem.findLastAny;
const lastIndexOfStr = std.mem.findLastLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
