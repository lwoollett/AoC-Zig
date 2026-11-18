const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day09.txt");

pub fn main() !void {
    const disk = trim(u8, data, " \n\r\t");

    // part 1: block-level compaction
    {
        var blocks: List(i64) = .empty;
        defer blocks.deinit(gpa);
        for (disk, 0..) |c, i| {
            const n = c - '0';
            const id: i64 = @intCast(i / 2);
            for (0..n) |_| {
                try blocks.append(gpa, if (i % 2 == 0) id else -1);
            }
        }
        var lo: usize = 0;
        var hi: usize = blocks.items.len;
        while (lo < hi) {
            hi -= 1;
            if (blocks.items[hi] == -1) continue;
            while (lo < hi and blocks.items[lo] != -1) lo += 1;
            if (lo >= hi) {
                hi += 1; // restore: last file block stays
                break;
            }
            blocks.items[lo] = blocks.items[hi];
            blocks.items[hi] = -1;
        }
        var checksum: u64 = 0;
        for (blocks.items, 0..) |b, i| {
            if (b >= 0) {
                checksum += @as(u64, @intCast(b)) * i;
            }
        }
        print("part 1: {d}\n", .{checksum});
    }

    // part 2: whole-file compaction
    {
        // files: (id, start, len); gaps tracked implicitly
        const n = disk.len;
        var files = try gpa.alloc([3]u64, (n + 1) / 2); // id, start, len
        defer gpa.free(files);
        var pos: u64 = 0;
        for (0..files.len) |i| {
            const len: u64 = disk[2 * i] - '0';
            files[i] = .{ i, pos, len };
            pos += len;
            if (2 * i + 1 < n) pos += disk[2 * i + 1] - '0';
        }
        // free-space table per length? classic: simulate with a memory map
        // rebuild disk as cells, move files from the end
        var cells: List(i64) = .empty;
        defer cells.deinit(gpa);
        {
            for (0..files.len) |i| {
                while (cells.items.len < files[i][1]) try cells.append(gpa, -1);
                for (0..files[i][2]) |_| try cells.append(gpa, @intCast(i));
            }
        }
        var fi: i64 = @as(i64, @intCast(files.len)) - 1;
        while (fi >= 0) : (fi -= 1) {
            const f = files[@intCast(fi)];
            // find leftmost free span of length f[2]
            var span_start: ?usize = null;
            var run: usize = 0;
            for (cells.items[0..f[1]], 0..) |c, i| {
                if (c == -1) {
                    if (run == 0) span_start = i;
                    run += 1;
                    if (run == f[2]) break;
                } else {
                    run = 0;
                }
            }
            if (run >= f[2] and span_start != null) {
                const s = span_start.?;
                for (0..f[2]) |k| {
                    cells.items[s + k] = fi;
                    cells.items[f[1] + k] = -1;
                }
            }
        }
        var checksum: u64 = 0;
        for (cells.items, 0..) |c, i| {
            if (c >= 0) {
                checksum += @as(u64, @intCast(c)) * i;
            }
        }
        print("part 2: {d}\n", .{checksum});
    }
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
