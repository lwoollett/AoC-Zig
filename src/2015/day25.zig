const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day25.txt");

const first_code: u64 = 20151125;
const multiplier: u64 = 252533;
const modulus: u64 = 33554393;

pub fn main() !void {
    // "Enter the code at row 2947, column 3029."
    var row: u64 = 0;
    var col: u64 = 0;
    var it = tokenizeAny(u8, data, " .,\n");
    while (it.next()) |tok| {
        if (std.mem.eql(u8, tok, "row")) {
            row = try parseInt(u64, it.next().?, 10);
        } else if (std.mem.eql(u8, tok, "column")) {
            col = try parseInt(u64, it.next().?, 10);
        }
    }

    // The grid fills along anti-diagonals; the code at (row, col) is the
    // (diag + col - 1)-th code, where diag = row + col - 2 is the number of
    // complete diagonals before it: diag(diag+1)/2 codes precede.
    const diag = row + col - 2;
    const index = diag * (diag + 1) / 2 + col - 1;

    var code = first_code;
    var i: u64 = 0;
    while (i < index) : (i += 1) {
        code = code *% multiplier % modulus;
    }
    print("part 1: {d}\n", .{code});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
