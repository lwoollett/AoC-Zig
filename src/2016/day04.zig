const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day04.txt");

fn checksumOk(name: []const u8, checksum: []const u8) bool {
    var counts: [26]u32 = @splat(0);
    for (name) |c| {
        if (c >= 'a' and c <= 'z') counts[c - 'a'] += 1;
    }
    // rank: count desc, letter asc
    var letters: [26]u8 = undefined;
    for (&letters, 0..) |*l, i| l.* = @intCast(i);
    std.mem.sort(u8, &letters, counts[0..], struct {
        fn lessThan(cnt: *[26]u32, a: u8, b: u8) bool {
            if (cnt[a] != cnt[b]) return cnt[a] > cnt[b];
            return a < b;
        }
    }.lessThan);
    for (checksum, 0..) |c, i| {
        if (letters[i] != c - 'a') return false;
    }
    return true;
}

fn decrypt(name: []const u8, sector: u32) void {
    var buf: [64]u8 = undefined;
    var n: usize = 0;
    for (name) |c| {
        if (c == '-') {
            buf[n] = ' ';
        } else {
            buf[n] = @intCast('a' + @as(u8, @intCast((c - 'a' + @as(u8, @intCast(sector % 26))) % 26)));
        }
        n += 1;
    }
    if (std.mem.eql(u8, buf[0..n], "northpole object storage")) {
        print("part 2: {d}\n", .{sector});
    }
}

pub fn main() !void {
    var sum: u64 = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // aaaaa-bbb-cc-d-dd-eee-[abxyz]
        const open = std.mem.findScalar(u8, line, '[').?;
        const close = std.mem.findScalar(u8, line, ']').?;
        const checksum = line[open + 1 .. close];
        const rest = line[0..open];
        const last_dash = std.mem.findScalarLast(u8, rest, '-').?;
        const name = rest[0..last_dash];
        const sector = try parseInt(u32, rest[last_dash + 1 ..], 10);

        if (checksumOk(name, checksum)) {
            sum += sector;
            decrypt(name, sector);
        }
    }
    print("part 1: {d}\n", .{sum});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
