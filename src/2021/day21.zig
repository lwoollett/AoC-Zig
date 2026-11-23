const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day21.txt");

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    const p1_start = try parseInt(u8, lines.next().?[28..], 10);
    const p2_start = try parseInt(u8, lines.next().?[28..], 10);

    // part 1: deterministic die
    {
        var pos = [2]u8{ p1_start, p2_start };
        var score = [2]u32{ 0, 0 };
        var die: u32 = 1;
        var rolls: u32 = 0;
        var turn: usize = 0;
        while (true) {
            var total: u32 = 0;
            for (0..3) |_| {
                total += die;
                die = die % 100 + 1;
                rolls += 1;
            }
            pos[turn] = (pos[turn] - 1 + @as(u8, @intCast(total % 10))) % 10 + 1;
            score[turn] += pos[turn];
            if (score[turn] >= 1000) {
                const loser = score[1 - turn];
                print("part 1: {d}\n", .{loser * rolls});
                break;
            }
            turn = 1 - turn;
        }
    }

    // part 2: quantum dice with memoized win counts
    {
        const State = struct { p1: u8, p2: u8, s1: u32, s2: u32, turn: u8 };
        var memo = Map(State, [2]u64).init(gpa);
        defer memo.deinit();

        // distribution of 3d3
        const dist = [_][2]u32{ .{ 3, 1 }, .{ 4, 3 }, .{ 5, 6 }, .{ 6, 7 }, .{ 7, 6 }, .{ 8, 3 }, .{ 9, 1 } };

        const Rec = struct {
            fn play(s: State, memo_p: *Map(State, [2]u64), dist_p: []const [2]u32) anyerror![2]u64 {
                if (s.s1 >= 21) return .{ 1, 0 };
                if (s.s2 >= 21) return .{ 0, 1 };
                if (memo_p.get(s)) |v| return v;
                var wins = [2]u64{ 0, 0 };
                for (dist_p) |d| {
                    var ns = s;
                    if (s.turn == 0) {
                        ns.p1 = (s.p1 - 1 + @as(u8, @intCast(d[0] % 10))) % 10 + 1;
                        ns.s1 += ns.p1;
                        ns.turn = 1;
                    } else {
                        ns.p2 = (s.p2 - 1 + @as(u8, @intCast(d[0] % 10))) % 10 + 1;
                        ns.s2 += ns.p2;
                        ns.turn = 0;
                    }
                    const sub = try play(ns, memo_p, dist_p);
                    wins[0] += sub[0] * d[1];
                    wins[1] += sub[1] * d[1];
                }
                try memo_p.put(s, wins);
                return wins;
            }
        };
        const wins = try Rec.play(.{ .p1 = p1_start, .p2 = p2_start, .s1 = 0, .s2 = 0, .turn = 0 }, &memo, &dist);
        print("part 2: {d}\n", .{@max(wins[0], wins[1])});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
