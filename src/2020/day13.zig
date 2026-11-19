const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day13.txt");

fn mod(a: i128, m: i128) i128 {
    return @mod(a, m);
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    const earliest = try parseInt(u64, lines.next().?, 10);
    const schedule = lines.next().?;

    // part 1: earliest bus
    var best_wait: u64 = std.math.maxInt(u64);
    var best_id: u64 = 0;
    {
        var it = tokenizeSca(u8, schedule, ',');
        while (it.next()) |tok| {
            if (tok[0] == 'x') continue;
            const id = try parseInt(u64, tok, 10);
            const wait = id - earliest % id;
            if (wait < best_wait) {
                best_wait = wait;
                best_id = id;
            }
        }
    }
    print("part 1: {d}\n", .{best_id * best_wait});

    // part 2: CRT — find t with t + offset ≡ 0 (mod id)
    var t: i128 = 0;
    var m: i128 = 1;
    var it = tokenizeSca(u8, schedule, ',');
    var offset: i128 = 0;
    while (it.next()) |tok| : (offset += 1) {
        if (tok[0] == 'x') continue;
        const id: i128 = try parseInt(i64, tok, 10);
        // t ≡ -offset (mod id)
        const r = mod(-offset, id);
        // find k: t + k*m ≡ r (mod id)
        const m_inv = modInverse(mod(m, id), id);
        const k = mod(mod(r - t, id) * m_inv, id);
        t += k * m;
        m *= id;
    }
    print("part 2: {d}\n", .{t});
}

/// Modular inverse via extended Euclid (modulus not necessarily prime).
fn modInverse(a_in: i128, m: i128) i128 {
    var old_r = mod(a_in, m);
    var r = m;
    var old_s: i128 = 1;
    var s: i128 = 0;
    while (r != 0) {
        const q = @divTrunc(old_r, r);
        const tmp = old_r - q * r;
        old_r = r;
        r = tmp;
        const tmp2 = old_s - q * s;
        old_s = s;
        s = tmp2;
    }
    return mod(old_s, m);
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSca = std.mem.tokenizeScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
