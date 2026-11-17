const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day12.txt");

const Parser = struct {
    src: []const u8,
    i: usize = 0,
    skip_red: bool, // part 2

    fn skipWs(self: *Parser) void {
        while (self.i < self.src.len and (self.src[self.i] == ' ' or
            self.src[self.i] == '\n' or self.src[self.i] == '\t' or self.src[self.i] == '\r')) self.i += 1;
    }

    /// Parses a string literal, returns true iff its content is `word`.
    fn parseStringIs(self: *Parser, word: []const u8) bool {
        // self.i points at the opening quote
        self.i += 1;
        const start = self.i;
        while (self.src[self.i] != '"') self.i += 1;
        const s = self.src[start..self.i];
        self.i += 1; // closing quote
        return std.mem.eql(u8, s, word);
    }

    fn parseNumber(self: *Parser) i64 {
        const start = self.i;
        if (self.src[self.i] == '-') self.i += 1;
        while (self.src[self.i] >= '0' and self.src[self.i] <= '9') self.i += 1;
        return std.fmt.parseInt(i64, self.src[start..self.i], 10) catch unreachable;
    }

    fn parseValue(self: *Parser) i64 {
        self.skipWs();
        const c = self.src[self.i];
        if (c == '{') return self.parseObject();
        if (c == '[') return self.parseArray();
        if (c == '"') {
            _ = self.parseStringIs("");
            return 0;
        }
        return self.parseNumber();
    }

    fn parseObject(self: *Parser) i64 {
        // self.i points at '{'
        self.i += 1;
        var sum: i64 = 0;
        var red = false;
        while (true) {
            self.skipWs();
            const c = self.src[self.i];
            if (c == '}') {
                self.i += 1;
                break;
            }
            if (c == ',') {
                self.i += 1;
                continue;
            }
            // key
            self.skipWs();
            _ = self.parseStringIs("");
            self.skipWs();
            self.i += 1; // ':'
            // value: need lookahead for "red" (string values only)
            self.skipWs();
            if (self.src[self.i] == '"') {
                if (self.parseStringIs("red")) {
                    if (self.skip_red) red = true;
                    continue;
                }
            } else {
                sum += self.parseValue();
            }
        }
        return if (red) 0 else sum;
    }

    fn parseArray(self: *Parser) i64 {
        // self.i points at '['
        self.i += 1;
        var sum: i64 = 0;
        while (true) {
            self.skipWs();
            const c = self.src[self.i];
            if (c == ']') {
                self.i += 1;
                break;
            }
            if (c == ',') {
                self.i += 1;
                continue;
            }
            sum += self.parseValue();
        }
        return sum;
    }
};

pub fn main() !void {
    var p1 = Parser{ .src = data, .skip_red = false };
    print("part 1: {d}\n", .{p1.parseValue()});

    var p2 = Parser{ .src = data, .skip_red = true };
    print("part 2: {d}\n", .{p2.parseValue()});
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
