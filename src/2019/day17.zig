const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;
const intcode = @import("intcode");


const data = @embedFile("data/day17.txt");

const gw = 60;
const gh = 60;

const Span = struct { s: usize, e: usize };

fn tokenStrLen(tokens: []const []const u8) usize {
    var n: usize = 0;
    for (tokens, 0..) |t, k| {
        n += t.len;
        if (k > 0) n += 1; // comma
    }
    return n;
}

fn tokenEq(x: []const []const u8, y: []const []const u8) bool {
    if (x.len != y.len) return false;
    for (x, y) |xs, ys| {
        if (!std.mem.eql(u8, xs, ys)) return false;
    }
    return true;
}

fn joinCommas(a: Allocator, tokens: []const []const u8) ![]const u8 {
    var buf: List(u8) = .empty;
    for (tokens, 0..) |t, k| {
        if (k > 0) try buf.append(a, ',');
        try buf.appendSlice(a, t);
    }
    return buf.items;
}

const Solver = struct {
    moves: []const []const u8,
    defs: [3]?Span = .{ null, null, null },
    main: List(u8) = .empty,
    a: Allocator,

    fn matches(self: *const Solver, span: Span, pos: usize) bool {
        const len = span.e - span.s;
        if (pos + len > self.moves.len) return false;
        return tokenEq(self.moves[span.s .. span.s + len], self.moves[pos .. pos + len]);
    }

    fn solve(self: *Solver, pos: usize) !bool {
        if (pos == self.moves.len) {
            for (self.defs) |d| {
                if (d == null) return false;
            }
            return self.main.items.len <= 20;
        }
        // try already-defined functions first
        for (self.defs, 0..) |d, fi| {
            if (d == null) continue;
            const len = d.?.e - d.?.s;
            if (self.matches(d.?, pos)) {
                const mark = self.main.items.len;
                if (self.main.items.len > 0) try self.main.append(self.a, ',');
                try self.main.append(self.a, "ABC"[fi]);
                if (try self.solve(pos + len)) return true;
                self.main.shrinkRetainingCapacity(mark);
            }
        }
        // define a new function starting at pos
        var k: usize = 1;
        while (pos + k <= self.moves.len and k < 12) : (k += 1) {
            if (tokenStrLen(self.moves[pos .. pos + k]) > 20) break;
            for (0..3) |fi| {
                if (self.defs[fi] != null) continue;
                self.defs[fi] = .{ .s = pos, .e = pos + k };
                const mark = self.main.items.len;
                if (self.main.items.len > 0) try self.main.append(self.a, ',');
                try self.main.append(self.a, "ABC"[fi]);
                if (try self.solve(pos + k)) return true;
                self.main.shrinkRetainingCapacity(mark);
                self.defs[fi] = null;
            }
        }
        return false;
    }
};

pub fn main() !void {
    var vm = try intcode.VM.initSource(gpa, data);
    defer vm.deinit();
    while (!vm.halted) _ = try vm.step();

    var grid: [gh][gw]u8 = @splat(@splat('.'));
    var w: usize = 0;
    var h: usize = 0;
    {
        var text: List(u8) = .empty;
        defer text.deinit(gpa);
        for (vm.outputs.items) |v| try text.append(gpa, @intCast(v));
        var it = std.mem.splitScalar(u8, text.items, '\n');
        while (it.next()) |line| {
            if (line.len == 0) continue;
            @memcpy(grid[h][0..line.len], line);
            w = @max(w, line.len);
            h += 1;
        }
    }

    // part 1: alignment parameters at intersections
    var alignment_sum: u64 = 0;
    for (1..h - 1) |y| {
        for (1..w - 1) |x| {
            if (grid[y][x] == '#' and grid[y - 1][x] == '#' and grid[y + 1][x] == '#' and
                grid[y][x - 1] == '#' and grid[y][x + 1] == '#')
            {
                alignment_sum += x * y;
            }
        }
    }
    print("part 1: {d}\n", .{alignment_sum});

    // part 2: walk the scaffold, collecting move tokens
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const a = arena.allocator();

    var rx: usize = 0;
    var ry: usize = 0;
    var rdx: i32 = 0;
    var rdy: i32 = -1;
    found: for (0..h) |y| {
        for (0..w) |x| {
            switch (grid[y][x]) {
                '^' => {
                    rx = x;
                    ry = y;
                    rdx = 0;
                    rdy = -1;
                    break :found;
                },
                'v' => {
                    rx = x;
                    ry = y;
                    rdx = 0;
                    rdy = 1;
                    break :found;
                },
                '<' => {
                    rx = x;
                    ry = y;
                    rdx = -1;
                    rdy = 0;
                    break :found;
                },
                '>' => {
                    rx = x;
                    ry = y;
                    rdx = 1;
                    rdy = 0;
                    break :found;
                },
                else => {},
            }
        }
    }

    var moves: List([]const u8) = .empty;
    while (true) {
        // move forward while scaffold
        var steps: u32 = 0;
        while (true) {
            const nx = @as(i32, @intCast(rx)) + rdx;
            const ny = @as(i32, @intCast(ry)) + rdy;
            if (nx < 0 or ny < 0 or ny >= gh or nx >= gw) break;
            if (grid[@intCast(ny)][@intCast(nx)] != '#') break;
            rx = @intCast(nx);
            ry = @intCast(ny);
            steps += 1;
        }
        if (steps > 0) {
            try moves.append(a, try std.fmt.allocPrint(a, "{d}", .{steps}));
        }
        // decide turn: left = (dy,-dx), right = (-dy,dx)
        const ldx = rdy;
        const ldy = -rdx;
        const rdx2 = -rdy;
        const rdy2 = rdx;
        const lx = @as(i32, @intCast(rx)) + ldx;
        const ly = @as(i32, @intCast(ry)) + ldy;
        const rx2 = @as(i32, @intCast(rx)) + rdx2;
        const ry2 = @as(i32, @intCast(ry)) + rdy2;
        const l_ok = lx >= 0 and ly >= 0 and ly < gh and lx < gw and grid[@intCast(ly)][@intCast(lx)] == '#';
        const r_ok = rx2 >= 0 and ry2 >= 0 and ry2 < gh and rx2 < gw and grid[@intCast(ry2)][@intCast(rx2)] == '#';
        if (l_ok and !r_ok) {
            try moves.append(a, "L");
            rdx = ldx;
            rdy = ldy;
        } else if (r_ok and !l_ok) {
            try moves.append(a, "R");
            rdx = rdx2;
            rdy = rdy2;
        } else {
            break; // path complete
        }
    }

    // NOTE: the vacuum robot parses "R,12,L,8" style input — turn and count
    // must be SEPARATE comma-separated tokens, so keep the raw token list.
    const move_strings = moves;

    // factorize into A, B, C
    var solver = Solver{ .moves = move_strings.items, .a = a };
    if (!try solver.solve(0)) {
        print("could not factorize moves ({d} tokens):", .{move_strings.items.len});
        for (move_strings.items) |m| print(" {s}", .{m});
        print("\n", .{});
        return;
    }

    var func_strings: [3][]const u8 = undefined;
    for (0..3) |fi| {
        const d = solver.defs[fi].?;
        func_strings[fi] = try joinCommas(a, move_strings.items[d.s..d.e]);
    }
    const main_line = solver.main.items;

    // feed the program
    var vm2 = try intcode.VM.initSource(gpa, data);
    defer vm2.deinit();
    try vm2.write(0, 2);
    const lines = [5][]const u8{ main_line, func_strings[0], func_strings[1], func_strings[2], "n" };
    var text_buf: List(u8) = .empty;
    defer text_buf.deinit(gpa);
    for (lines) |l| {
        try text_buf.appendSlice(gpa, l);
        try text_buf.append(gpa, '\n');
    }
    for (text_buf.items) |c| try vm2.addInput(c);
    while (!vm2.halted) _ = try vm2.step();
    print("part 2: {d}\n", .{vm2.lastOutput()});
}

// Useful stdlib functions

const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
