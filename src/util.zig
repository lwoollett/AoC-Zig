const std = @import("std");

var gpa_impl: std.heap.DebugAllocator(.{}) = .init;

/// Debug allocator in debug builds; raw page allocator in release builds
/// (DebugAllocator's safety bookkeeping dwarfs hot-loop allocation costs).
const build_mode: std.builtin.OptimizeMode = @import("builtin").mode;
pub const gpa = if (build_mode == .debug)
    gpa_impl.allocator()
else
    std.heap.page_allocator;

// Add utility functions here

/// 4-lane parallel single-block MD5 for short messages (<= 55 bytes).
/// All hash-bound AoC days (2015 d4, 2016 d5/d14) hash "prefix ++ decimal(i)"
/// strings, which never exceed 55 bytes, so one padded block per message
/// is enough — and 4 independent messages ride one NEON vector pipeline.
const V4 = @Vector(4, u32);

const md5_k: [64]u32 = blk: {
    @setEvalBranchQuota(10000);
    var t: [64]u32 = undefined;
    for (0..64) |i| {
        const x: f64 = @abs(@sin(@as(f64, @floatFromInt(i + 1))));
        t[i] = @intFromFloat(x * 4294967296.0);
    }
    break :blk t;
};

fn md5Rotl(v: V4, comptime r: u5) V4 {
    return (v << @as(V4, @splat(r))) | (v >> @as(V4, @splat(32 - @as(u6, r))));
}

const Chain = struct {
    a: V4,
    b: V4,
    c: V4,
    d: V4,
    m: [16]V4,

    fn build(msgs: [4][]const u8) Chain {
        // per-lane padded block, transposed to [16]V4 (vector element access
        // needs comptime-known indices, so build a scalar [lane][word] array first)
        var words: [4][16]u32 = undefined;
        for (0..4) |lane| {
            const msg = msgs[lane];
            var block: [64]u8 = @splat(0);
            @memcpy(block[0..msg.len], msg);
            block[msg.len] = 0x80;
            std.mem.writeInt(u32, block[56..60], @intCast(msg.len * 8), .little);
            for (0..16) |w| {
                words[lane][w] = std.mem.readInt(u32, block[w * 4 ..][0..4], .little);
            }
        }
        var m: [16]V4 = undefined;
        for (0..16) |w| {
            m[w] = .{ words[0][w], words[1][w], words[2][w], words[3][w] };
        }
        return .{
            .a = @splat(0x67452301),
            .b = @splat(0xefcdab89),
            .c = @splat(0x98badcfe),
            .d = @splat(0x10325476),
            .m = m,
        };
    }

    inline fn step(self: *Chain, comptime i: usize) void {
        const f: V4 = if (i < 16)
            (self.b & self.c) | (~self.b & self.d)
        else if (i < 32)
            (self.d & self.b) | (~self.d & self.c)
        else if (i < 48)
            self.b ^ self.c ^ self.d
        else
            self.c ^ (self.b | ~self.d);
        const g: usize = if (i < 16)
            i
        else if (i < 32)
            (5 * i + 1) % 16
        else if (i < 48)
            (3 * i + 5) % 16
        else
            (7 * i) % 16;
        const s: u5 = @intCast(switch (i / 16) {
            0 => &[_]u32{ 7, 12, 17, 22 },
            1 => &[_]u32{ 5, 9, 14, 20 },
            2 => &[_]u32{ 4, 11, 16, 23 },
            else => &[_]u32{ 6, 10, 15, 21 },
        }[i % 4]);
        const tmp = self.d;
        self.d = self.c;
        self.c = self.b;
        self.b = self.b +% md5Rotl(self.a +% f +% @as(V4, @splat(md5_k[i])) +% self.m[g], s);
        self.a = tmp;
    }

    fn extract(self: *const Chain, digests: *[4][16]u8) void {
        const fa = self.a +% @as(V4, @splat(0x67452301));
        const fb = self.b +% @as(V4, @splat(0xefcdab89));
        const fc = self.c +% @as(V4, @splat(0x98badcfe));
        const fd = self.d +% @as(V4, @splat(0x10325476));
        inline for (0..4) |lane| {
            std.mem.writeInt(u32, digests[lane][0..4], fa[lane], .little);
            std.mem.writeInt(u32, digests[lane][4..8], fb[lane], .little);
            std.mem.writeInt(u32, digests[lane][8..12], fc[lane], .little);
            std.mem.writeInt(u32, digests[lane][12..16], fd[lane], .little);
        }
    }
};

pub const md5x4 = struct {
    /// Hash four independent messages (each <= 55 bytes) simultaneously.
    pub fn hash(msgs: [4][]const u8, digests: *[4][16]u8) void {
        var ch = Chain.build(msgs);
        inline for (0..64) |i| ch.step(i);
        ch.extract(digests);
    }

    /// Hash eight independent messages with two interleaved 4-lane chains —
    /// the MD5 round chain is latency-bound, so a second in-flight chain
    /// nearly doubles per-core throughput.
    pub fn hash8(msgs: [8][]const u8, digests: *[8][16]u8) void {
        var ch1 = Chain.build(msgs[0..4].*);
        var ch2 = Chain.build(msgs[4..8].*);
        inline for (0..64) |i| {
            ch1.step(i);
            ch2.step(i);
        }
        ch1.extract(digests[0..4]);
        ch2.extract(digests[4..8]);
    }
};

test "md5x4 matches RFC 1321 vectors" {
    const vectors = [_][]const u8{
        "",
        "a",
        "abc",
        "message digest",
        "abcdefghijklmnopqrstuvwxyz",
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
    };
    const want = [_][32]u8{
        "d41d8cd98f00b204e9800998ecf8427e".*,
        "0cc175b9c0f1b6a831c399e269772661".*,
        "900150983cd24fb0d6963f7d28e17f72".*,
        "f96b697d7cb7938d525a2f31aaf161d0".*,
        "c3fcd3d76192e4007dfb496cca67e13b".*,
        "d174ab98d277d9f5a5611c2c9f419d9f".*,
    };
    const hex = "0123456789abcdef";
    var digests: [4][16]u8 = undefined;
    for (vectors, 0..) |_, set| {
        const msgs: [4][]const u8 = .{ vectors[set], vectors[set], vectors[set], vectors[set] };
        md5x4.hash(msgs, &digests);
        for (0..4) |lane| {
            var got: [32]u8 = undefined;
            for (digests[lane], 0..) |byte, i| {
                got[i * 2] = hex[byte >> 4];
                got[i * 2 + 1] = hex[byte & 0xf];
            }
            try std.testing.expectEqualSlices(u8, &want[set], &got);
        }
        // hash8: the six vectors padded to 8 lanes with repeats
        var digests8: [8][16]u8 = undefined;
        var msgs8: [8][]const u8 = undefined;
        for (0..8) |lane| msgs8[lane] = vectors[@min(lane, vectors.len - 1)];
        md5x4.hash8(msgs8, &digests8);
        for (0..8) |lane| {
            const w = &want[@min(lane, want.len - 1)];
            var got: [32]u8 = undefined;
            for (digests8[lane], 0..) |byte, i| {
                got[i * 2] = hex[byte >> 4];
                got[i * 2 + 1] = hex[byte & 0xf];
            }
            try std.testing.expectEqualSlices(u8, w, &got);
        }
    }
}

test {
    _ = &gpa_impl;
}
