const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day18.txt");

const Parser = struct {
    s: []const u8,
    i: usize = 0,
    plus_high: bool, // part 2 semantics

    fn peek(self: *Parser) u8 {
        if (self.i >= self.s.len) return 0;
        return self.s[self.i];
    }

    /// atom := number | '(' expr ')'
    fn atom(self: *Parser) u64 {
        while (self.peek() == ' ') self.i += 1;
        if (self.peek() == '(') {
            self.i += 1;
            const v = self.expr();
            while (self.peek() == ' ') self.i += 1;
            if (self.peek() == ')') self.i += 1;
            return v;
        }
        var v: u64 = 0;
        while (self.peek() >= '0' and self.peek() <= '9') {
            v = v * 10 + (self.peek() - '0');
            self.i += 1;
        }
        return v;
    }

    /// part 1: left-to-right accumulation of '+'/'*' (same precedence)
    /// part 2: term = atom (+ atom)*  — '+' binds tighter
    fn term(self: *Parser) u64 {
        var v = self.atom();
        while (true) {
            while (self.peek() == ' ') self.i += 1;
            if (self.plus_high and self.peek() == '+') {
                self.i += 1;
                v += self.atom();
            } else break;
        }
        return v;
    }

    fn expr(self: *Parser) u64 {
        if (!self.plus_high) {
            // flat left-to-right
            var v = self.term();
            while (true) {
                while (self.peek() == ' ') self.i += 1;
                const c = self.peek();
                if (c == '+' or c == '*') {
                    self.i += 1;
                    const r = self.term();
                    v = if (c == '+') v + r else v * r;
                } else break;
            }
            return v;
        } else {
            var v = self.term();
            while (true) {
                while (self.peek() == ' ') self.i += 1;
                if (self.peek() == '*') {
                    self.i += 1;
                    v *= self.term();
                } else break;
            }
            return v;
        }
    }
};

fn evalAll(comptime plus_high: bool) !u64 {
    var total: u64 = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var p = Parser{ .s = line, .plus_high = plus_high };
        total += p.expr();
    }
    return total;
}

pub fn main() !void {
    print("part 1: {d}\n", .{try evalAll(false)});
    print("part 2: {d}\n", .{try evalAll(true)});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
