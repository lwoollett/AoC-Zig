//! Intcode virtual machine — the workhorse of AoC 2019.
//!
//! Supports: parameter modes (position, immediate, relative), growable
//! memory, buffered input/output, and incremental execution (step/run-until)
//! for the amplifier, network, and interactive-puzzle days.

const std = @import("std");

pub const StepResult = enum { ok, output, need_input, halt };

pub const VM = struct {
    alloc: std.mem.Allocator,
    mem: std.ArrayListUnmanaged(i64) = .empty,
    pc: usize = 0,
    rel: i64 = 0,
    inputs: std.ArrayListUnmanaged(i64) = .empty,
    in_head: usize = 0,
    outputs: std.ArrayListUnmanaged(i64) = .empty,
    halted: bool = false,

    pub fn init(alloc: std.mem.Allocator, program: []const i64) !VM {
        var vm = VM{ .alloc = alloc };
        try vm.mem.appendSlice(alloc, program);
        // pre-grow so the step hot path rarely needs ensureMem
        if (vm.mem.items.len < 8192) {
            const old = vm.mem.items.len;
            try vm.mem.resize(alloc, 8192);
            @memset(vm.mem.items[old..], 0);
        }
        return vm;
    }

    /// Faster init for repeated probes: clone an already-parsed program.
    pub fn initClone(self: *const VM, alloc: std.mem.Allocator) !VM {
        var vm = VM{ .alloc = alloc };
        try vm.mem.appendSlice(alloc, self.mem.items);
        return vm;
    }

    pub fn initSource(alloc: std.mem.Allocator, src: []const u8) !VM {
        var program: std.ArrayListUnmanaged(i64) = .empty;
        defer program.deinit(alloc);
        var it = std.mem.tokenizeAny(u8, src, ", \n\r\t");
        while (it.next()) |tok| {
            try program.append(alloc, try std.fmt.parseInt(i64, tok, 10));
        }
        return init(alloc, program.items);
    }

    pub fn deinit(self: *VM) void {
        self.mem.deinit(self.alloc);
        self.inputs.deinit(self.alloc);
        self.outputs.deinit(self.alloc);
    }

    pub fn addInput(self: *VM, v: i64) !void {
        try self.inputs.append(self.alloc, v);
    }

    pub fn lastOutput(self: *const VM) i64 {
        return self.outputs.items[self.outputs.items.len - 1];
    }

    pub fn outputCount(self: *const VM) usize {
        return self.outputs.items.len;
    }

    fn ensureMem(self: *VM, addr: i64) !void {
        if (addr < 0) return error.NegativeAddress;
        const idx: usize = @intCast(addr);
        if (idx >= self.mem.items.len) {
            const old = self.mem.items.len;
            try self.mem.resize(self.alloc, idx + 1);
            @memset(self.mem.items[old..], 0);
        }
    }

    fn read(self: *VM, addr: i64) !i64 {
        try self.ensureMem(addr);
        return self.mem.items[@intCast(addr)];
    }

    pub fn write(self: *VM, addr: i64, v: i64) !void {
        try self.ensureMem(addr);
        self.mem.items[@intCast(addr)] = v;
    }

    /// Operand fetch: mode 0 position, 1 immediate, 2 relative.
    fn operandAddr(self: *VM, mode: i64, value: i64) !i64 {
        return switch (mode) {
            0 => value,
            1 => blk: {
                // immediate: encoded as a "virtual address" handled by caller
                break :blk std.math.minInt(i64); // sentinel; caller uses value directly
            },
            2 => self.rel + value,
            else => error.BadMode,
        };
    }

    /// Executes one instruction. Tight interpreter loop: local slice, hoisted
    /// pc/rel, inlined operand decode; slice refresh only on memory growth.
    pub fn step(self: *VM) !StepResult {
        if (self.halted) return .halt;
        var mem = self.mem.items;
        const pc = self.pc;
        const raw = mem[pc];
        const op: i64 = @mod(raw, 100);
        const mode1 = @mod(@divTrunc(raw, 100), 10);
        const mode2 = @mod(@divTrunc(raw, 1000), 10);
        const mode3 = @mod(@divTrunc(raw, 10000), 10);

        // fetch operand value at pc+k, resolving position/relative modes
        const S = struct {
            inline fn ld(m: [*]i64, v: i64, mode: i64, rel: i64) i64 {
                if (mode == 1) return v;
                const addr = if (mode == 2) rel + v else v;
                return m[@intCast(addr)];
            }
            inline fn st(mode: i64, v: i64, rel: i64) i64 {
                return if (mode == 2) rel + v else v;
            }
        };

        switch (op) {
            1, 2 => {
                const a = S.ld(mem.ptr, mem[pc + 1], mode1, self.rel);
                const b = S.ld(mem.ptr, mem[pc + 2], mode2, self.rel);
                const dst = S.st(mode3, mem[pc + 3], self.rel);
                try self.ensureMem(dst);
                mem = self.mem.items;
                mem[@intCast(dst)] = if (op == 1) a + b else a * b;
                self.pc = pc + 4;
            },
            3 => {
                if (self.in_head >= self.inputs.items.len) return .need_input;
                const v = self.inputs.items[self.in_head];
                self.in_head += 1;
                const dst = S.st(mode1, mem[pc + 1], self.rel);
                try self.ensureMem(dst);
                mem = self.mem.items;
                mem[@intCast(dst)] = v;
                self.pc = pc + 2;
            },
            4 => {
                const v = S.ld(mem.ptr, mem[pc + 1], mode1, self.rel);
                try self.outputs.append(self.alloc, v);
                self.pc = pc + 2;
                return .output;
            },
            5, 6 => {
                const cond = S.ld(mem.ptr, mem[pc + 1], mode1, self.rel);
                const target = S.ld(mem.ptr, mem[pc + 2], mode2, self.rel);
                const jump = if (op == 5) cond != 0 else cond == 0;
                self.pc = if (jump) @intCast(target) else pc + 3;
            },
            7, 8 => {
                const a = S.ld(mem.ptr, mem[pc + 1], mode1, self.rel);
                const b = S.ld(mem.ptr, mem[pc + 2], mode2, self.rel);
                const dst = S.st(mode3, mem[pc + 3], self.rel);
                const v: i64 = if (op == 7)
                    @intFromBool(a < b)
                else
                    @intFromBool(a == b);
                try self.ensureMem(dst);
                mem = self.mem.items;
                mem[@intCast(dst)] = v;
                self.pc = pc + 4;
            },
            9 => {
                self.rel += S.ld(mem.ptr, mem[pc + 1], mode1, self.rel);
                self.pc = pc + 2;
            },
            99 => {
                self.halted = true;
                return .halt;
            },
            else => return error.BadOpcode,
        }
        return .ok;
    }

    /// Runs until halt or until it needs input.
    pub fn run(self: *VM) !StepResult {
        while (true) {
            const r = try self.step();
            if (r != .ok) return r;
        }
    }

    /// Runs until halt, feeding `input` whenever input is needed.
    /// Outputs are buffered (does NOT stop at .output).
    pub fn runWith(self: *VM, input: i64) !StepResult {
        while (true) {
            const r = try self.step();
            if (r == .need_input) {
                try self.addInput(input);
                continue;
            }
            if (r == .halt) return r;
        }
    }
};
