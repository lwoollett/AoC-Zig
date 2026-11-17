const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day13.txt");

const gw = 200;
const gh = 200;
var grid: [gh][gw]u8 = @splat(@splat(' '));
var w: usize = 0;
var h: usize = 0;

const Cart = struct {
    x: usize,
    y: usize,
    dx: i8,
    dy: i8,
    turn: u2, // 0=left,1=straight,2=right cycling
    alive: bool = true,
};

var carts: List(Cart) = .empty;

fn turnLeft(c: *Cart) void {
    const t = c.dx;
    c.dx = c.dy;
    c.dy = -t;
}
fn turnRight(c: *Cart) void {
    const t = c.dx;
    c.dx = -c.dy;
    c.dy = t;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        @memcpy(grid[h][0..line.len], line);
        w = @max(w, line.len);
        h += 1;
    }
    defer carts.deinit(gpa);

    // find carts; reconstruct the track beneath from DIRECTIONAL connectivity
    // (a neighbor only counts if its piece connects toward this cell)
    const Vert = struct {
        fn is(c: u8) bool {
            return c == '|' or c == '+' or c == '^' or c == 'v';
        }
    };
    const Horiz = struct {
        fn is(c: u8) bool {
            return c == '-' or c == '+' or c == '<' or c == '>';
        }
    };
    for (0..h) |y| {
        for (0..w) |x| {
            const c = grid[y][x];
            const dir: ?[2]i8 = switch (c) {
                '^' => .{ 0, -1 },
                'v' => .{ 0, 1 },
                '<' => .{ -1, 0 },
                '>' => .{ 1, 0 },
                else => null,
            };
            if (dir) |d| {
                try carts.append(gpa, .{ .x = x, .y = y, .dx = d[0], .dy = d[1], .turn = 0 });
                const up = y > 0 and Vert.is(grid[y - 1][x]);
                const down = y + 1 < h and Vert.is(grid[y + 1][x]);
                const left = x > 0 and Horiz.is(grid[y][x - 1]);
                const right = x + 1 < w and Horiz.is(grid[y][x + 1]);
                if (c == '<' or c == '>') {
                    if (up and down) {
                        grid[y][x] = '+';
                    } else if (left and right) {
                        grid[y][x] = '-';
                    } else if (up) {
                        grid[y][x] = '/';
                    } else {
                        grid[y][x] = '\\';
                    }
                } else {
                    if (left and right) {
                        grid[y][x] = '+';
                    } else if (up and down) {
                        grid[y][x] = '|';
                    } else if (right) {
                        grid[y][x] = '/';
                    } else {
                        grid[y][x] = '\\';
                    }
                }
            }
        }
    }

    var first_crash: ?[2]usize = null;
    var ticks: u64 = 0;
    while (ticks < 100000) : (ticks += 1) {
        // reading order: sort alive carts by y then x
        std.mem.sort(Cart, carts.items, {}, struct {
            fn lessThan(_: void, a: Cart, b: Cart) bool {
                if (a.y != b.y) return a.y < b.y;
                return a.x < b.x;
            }
        }.lessThan);

        for (carts.items) |*cart| {
            if (!cart.alive) continue;
            // move
            const nx: usize = @intCast(@as(i64, @intCast(cart.x)) + cart.dx);
            const ny: usize = @intCast(@as(i64, @intCast(cart.y)) + cart.dy);
            cart.x = nx;
            cart.y = ny;

            // track interaction
            switch (grid[ny][nx]) {
                '+' => {
                    switch (cart.turn) {
                        0 => turnLeft(cart),
                        1 => {},
                        2 => turnRight(cart),
                        3 => {},
                    }
                    cart.turn = (cart.turn + 1) % 3;
                },
                else => {},
            }
            switch (grid[ny][nx]) {
                '/' => {
                    // moving horizontally -> vertical: (dx,0)->(0,-dx); (0,dy)->(-dy,0)
                    if (cart.dx != 0) {
                        const dx = cart.dx;
                        cart.dx = 0;
                        cart.dy = -dx;
                    } else {
                        const dy = cart.dy;
                        cart.dx = -dy;
                        cart.dy = 0;
                    }
                },
                '\\' => {
                    if (cart.dx != 0) {
                        const dx = cart.dx;
                        cart.dx = 0;
                        cart.dy = dx;
                    } else {
                        const dy = cart.dy;
                        cart.dx = dy;
                        cart.dy = 0;
                    }
                },
                else => {},
            }

            // collisions
            for (carts.items) |*other| {
                if (other == cart or !other.alive) continue;
                if (other.x == cart.x and other.y == cart.y) {
                    cart.alive = false;
                    other.alive = false;
                    if (first_crash == null) first_crash = .{ cart.x, cart.y };
                }
            }
        }

        var alive_count: usize = 0;
        var last: ?Cart = null;
        for (carts.items) |c| {
            if (c.alive) {
                alive_count += 1;
                last = c;
            }
        }
        if (alive_count == 1) {
            const l = last.?;
            print("part 1: {d},{d}\n", .{ first_crash.?[0], first_crash.?[1] });
            print("part 2: {d},{d}\n", .{ l.x, l.y });
            return;
        }
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
