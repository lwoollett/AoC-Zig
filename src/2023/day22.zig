const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day22.txt");

const Brick = struct {
    x0: i64,
    y0: i64,
    z0: i64,
    x1: i64,
    y1: i64,
    z1: i64,
};

var bricks: List(Brick) = .empty;

/// settle all bricks (sort by base, drop onto the height map); returns how
/// many moved
fn settle() !usize {
    std.mem.sort(Brick, bricks.items, {}, struct {
        fn lessThan(_: void, a: Brick, b: Brick) bool {
            return a.z0 < b.z0;
        }
    }.lessThan);
    var moved: usize = 0;
    // top surface map: [x][y] = highest z occupied
    var top = try gpa.alloc([]i64, 400);
    defer {
        for (top) |r| gpa.free(r);
        gpa.free(top);
    }
    for (top) |*r| {
        r.* = try gpa.alloc(i64, 400);
        @memset(r.*, 0);
    }
    for (bricks.items) |*b| {
        var landing: i64 = 0;
        var x = b.x0;
        while (x <= b.x1) : (x += 1) {
            var y = b.y0;
            while (y <= b.y1) : (y += 1) {
                landing = @max(landing, top[@intCast(x)][@intCast(y)]);
            }
        }
        const height = b.z1 - b.z0;
        if (b.z0 != landing) moved += 1;
        b.z0 = landing;
        b.z1 = landing + height;
        x = b.x0;
        while (x <= b.x1) : (x += 1) {
            var y = b.y0;
            while (y <= b.y1) : (y += 1) {
                top[@intCast(x)][@intCast(y)] = b.z1 + 1;
            }
        }
    }
    return moved;
}

fn zLessThan(_: void, a: Brick, b: Brick) bool {
    return a.z0 < b.z0;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "1,0,1~1,2,1"
        const tilde = indexOf(u8, line, '~').?;
        var c1: [3]i64 = undefined;
        var c2: [3]i64 = undefined;
        var it1 = tokenizeSca(u8, line[0..tilde], ',');
        var i: usize = 0;
        while (it1.next()) |tok| : (i += 1) {
            c1[i] = try parseInt(i64, tok, 10);
        }
        var it2 = tokenizeSca(u8, line[tilde + 1 ..], ',');
        i = 0;
        while (it2.next()) |tok| : (i += 1) {
            c2[i] = try parseInt(i64, tok, 10);
        }
        try bricks.append(gpa, .{
            .x0 = @min(c1[0], c2[0]),
            .y0 = @min(c1[1], c2[1]),
            .z0 = @min(c1[2], c2[2]),
            .x1 = @max(c1[0], c2[0]),
            .y1 = @max(c1[1], c2[1]),
            .z1 = @max(c1[2], c2[2]),
        });
    }

    _ = try settle(); // settle once
    std.mem.sort(Brick, bricks.items, {}, zLessThan); // by settled base height

    const n = bricks.items.len;

    // support graph: sweep settled bricks bottom-up, tracking which brick
    // owns each column's top surface. A brick's supporters are the distinct
    // owners of the cells exactly one unit below its base.
    const no_owner: usize = std.math.maxInt(usize);
    var top_z = try gpa.alloc([]i64, 400);
    defer {
        for (top_z) |r| gpa.free(r);
        gpa.free(top_z);
    }
    var owner = try gpa.alloc([]usize, 400);
    defer {
        for (owner) |r| gpa.free(r);
        gpa.free(owner);
    }
    for (0..400) |x| {
        top_z[x] = try gpa.alloc(i64, 400);
        owner[x] = try gpa.alloc(usize, 400);
        @memset(top_z[x], 0);
        @memset(owner[x], no_owner);
    }

    var supporters = try gpa.alloc([]usize, n);
    defer {
        for (supporters) |s| gpa.free(s);
        gpa.free(supporters);
    }
    var sup_buf: List(usize) = .empty;
    defer sup_buf.deinit(gpa);
    for (bricks.items, 0..) |b, bi| {
        sup_buf.clearRetainingCapacity();
        var x = b.x0;
        while (x <= b.x1) : (x += 1) {
            var y = b.y0;
            while (y <= b.y1) : (y += 1) {
                const xi: usize = @intCast(x);
                const yi: usize = @intCast(y);
                if (top_z[xi][yi] == b.z0 and owner[xi][yi] != no_owner) {
                    const s = owner[xi][yi];
                    var dup = false;
                    for (sup_buf.items) |e| {
                        if (e == s) dup = true;
                    }
                    if (!dup) try sup_buf.append(gpa, s);
                }
            }
        }
        supporters[bi] = try gpa.dupe(usize, sup_buf.items);
        x = b.x0;
        while (x <= b.x1) : (x += 1) {
            var y = b.y0;
            while (y <= b.y1) : (y += 1) {
                top_z[@intCast(x)][@intCast(y)] = b.z1 + 1;
                owner[@intCast(x)][@intCast(y)] = bi;
            }
        }
    }

    // part 1: a brick is unsafe if some brick rests on it alone
    var unsafe = try gpa.alloc(bool, n);
    defer gpa.free(unsafe);
    @memset(unsafe, false);
    for (supporters) |sup| {
        if (sup.len == 1) unsafe[sup[0]] = true;
    }
    var safe: usize = 0;
    for (unsafe) |u| {
        if (!u) safe += 1;
    }
    print("part 1: {d}\n", .{safe});

    // part 2: per removed brick, cascade via falling supporter counts
    // (inverse support lists + Kahn-style propagation)
    var supportees = try gpa.alloc(List(usize), n);
    defer {
        for (supportees) |*l| l.deinit(gpa);
        gpa.free(supportees);
    }
    for (0..n) |i| supportees[i] = .empty;
    for (supporters, 0..) |sup, c| {
        for (sup) |s| {
            try supportees[s].append(gpa, c);
        }
    }

    var counts = try gpa.alloc(u32, n);
    defer gpa.free(counts);
    for (supporters, 0..) |sup, i| counts[i] = @intCast(sup.len);

    var falling = try gpa.alloc(bool, n);
    defer gpa.free(falling);
    var queue = try gpa.alloc(usize, n);
    defer gpa.free(queue);

    var total_falls: usize = 0;
    for (0..n) |r| {
        @memset(falling, false);
        for (supporters, 0..) |sup, i| counts[i] = @intCast(sup.len);
        var q_head: usize = 0;
        var q_tail: usize = 0;
        falling[r] = true;
        queue[q_tail] = r;
        q_tail += 1;
        while (q_head < q_tail) {
            const s = queue[q_head];
            q_head += 1;
            for (supportees[s].items) |c| {
                if (falling[c]) continue;
                counts[c] -= 1;
                if (counts[c] == 0) {
                    falling[c] = true;
                    total_falls += 1;
                    queue[q_tail] = c;
                    q_tail += 1;
                }
            }
        }
    }
    print("part 2: {d}\n", .{total_falls});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSca = std.mem.tokenizeScalar;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
