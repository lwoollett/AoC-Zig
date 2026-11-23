const std = @import("std");
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day07.txt");

const Op = enum { set, and_, or_, lshift, rshift, not };

const Operand = union(enum) {
    wire: []const u8,
    lit: u16,
};

const Instr = struct {
    op: Op,
    lhs: Operand,
    rhs: ?Operand, // only shift/rhs for and/or/shift; null for set/not
};

const Circuit = struct {
    instrs: StrMap(Instr),
    cache: StrMap(u16),
    override: ?[]const u8, // wire name
    override_val: u16,

    fn operandValue(self: *Circuit, o: Operand) !u16 {
        return switch (o) {
            .lit => |v| v,
            .wire => |w| self.eval(w),
        };
    }

    fn eval(self: *Circuit, wire: []const u8) anyerror!u16 {
        if (self.override) |ow| {
            if (std.mem.eql(u8, wire, ow)) return self.override_val;
        }
        if (self.cache.get(wire)) |v| return v;

        const instr = self.instrs.get(wire) orelse return error.UnknownWire;
        var v: u16 = undefined;
        switch (instr.op) {
            .set => v = try self.operandValue(instr.lhs),
            .not => v = ~(try self.operandValue(instr.lhs)),
            .and_ => v = try self.operandValue(instr.lhs) & try self.operandValue(instr.rhs.?),
            .or_ => v = try self.operandValue(instr.lhs) | try self.operandValue(instr.rhs.?),
            .lshift => {
                const shift: u4 = @intCast(try self.operandValue(instr.rhs.?));
                v = (try self.operandValue(instr.lhs)) << shift;
            },
            .rshift => {
                const shift: u4 = @intCast(try self.operandValue(instr.rhs.?));
                v = (try self.operandValue(instr.lhs)) >> shift;
            },
        }
        try self.cache.put(wire, v);
        return v;
    }
};

fn parseOperand(s: []const u8) Operand {
    if (parseInt(u16, s, 10)) |v| {
        return .{ .lit = v };
    } else |_| {
        return .{ .wire = s };
    }
}

pub fn main() !void {
    var instrs = StrMap(Instr).init(gpa);
    defer instrs.deinit();

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // Split "LHS -> RHS"
        const arrow = std.mem.findScalar(u8, line, '>').?;
        const lhs_str = trim(u8, line[0 .. arrow - 1], " ");
        const rhs_str = trim(u8, line[arrow + 1 ..], " ");

        var instr: Instr = undefined;
        if (std.mem.find(u8, lhs_str, "LSHIFT") != null or
            std.mem.find(u8, lhs_str, "RSHIFT") != null or
            std.mem.find(u8, lhs_str, "AND") != null or
            std.mem.find(u8, lhs_str, "OR") != null)
        {
            // Binary: "A OP B" — skip the operator token between operands.
            var it = tokenizeAny(u8, lhs_str, " ");
            const lhs_tok = it.next().?;
            const op_tok = it.next().?;
            const rhs_tok = it.next().?;
            const op: Op = if (std.mem.eql(u8, op_tok, "AND"))
                .and_
            else if (std.mem.eql(u8, op_tok, "OR"))
                .or_
            else if (std.mem.eql(u8, op_tok, "LSHIFT"))
                .lshift
            else
                .rshift;
            instr = .{ .op = op, .lhs = parseOperand(lhs_tok), .rhs = parseOperand(rhs_tok) };
        } else if (std.mem.find(u8, lhs_str, "NOT") != null) {
            // Unary: "NOT A".
            var it = tokenizeAny(u8, lhs_str, " ");
            _ = it.next();
            instr = .{ .op = .not, .lhs = parseOperand(it.next().?), .rhs = null };
        } else {
            instr = .{ .op = .set, .lhs = parseOperand(lhs_str), .rhs = null };
        }
        try instrs.put(rhs_str, instr);
    }

    var circuit = Circuit{
        .instrs = instrs,
        .cache = StrMap(u16).init(gpa),
        .override = null,
        .override_val = 0,
    };
    defer circuit.cache.deinit();

    const a = try circuit.eval("a");
    print("part 1: {d}\n", .{a});

    // Part 2: b is overridden with a's value; recompute a from scratch.
    var circuit2 = Circuit{
        .instrs = instrs,
        .cache = StrMap(u16).init(gpa),
        .override = "b",
        .override_val = a,
    };
    defer circuit2.cache.deinit();
    print("part 2: {d}\n", .{try circuit2.eval("a")});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
