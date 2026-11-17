const std = @import("std");

const first_year = 2015;
const last_year = 2026; // bump when the next AoC starts (keep in sync with template/generate.zig)

const required_zig_version = std.SemanticVersion.parse("0.17.0") catch unreachable;

pub fn build(b: *std.Build) void {
    if (comptime @import("builtin").zig_version.order(required_zig_version) == .lt) {
        std.debug.print("Zig 0.17.0 or newer is required for this project.\n", .{});
        std.process.exit(1);
    }

    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    // zom Managed Object Runtime (~/repos/zom), wired in per-day on demand.
    const zom_dep = b.dependency("zom", .{ .target = target, .optimize = mode });
    const zom = zom_dep.module("zom");

    // zom is OPT-IN per day: a day gets the zom module (and its vendored
    // SQLite) wired in only if its source references `@import("zom")`.
    // Scanning 300 small files at configure time is negligible; the payoff
    // is that ordinary days build small and fast.
    const zom_marker = "@import(\"zom\")";

    // Shared helpers, importable from any day as `@import("util")`.
    // (A day file's module is rooted at src/<year>/, so a relative
    // `../util.zig` import would escape the module path.)
    const util = b.createModule(.{
        .root_source_file = b.path("src/util.zig"),
        .target = target,
        .optimize = mode,
    });

    const install_all = b.step("install_all", "Install all days");
    const run_all = b.step("run_all", "Run all days");

    const generate = b.step("generate", "Generate day stubs from template/template.zig (only overwrites unmodified files)");
    const generate_exe = b.addExecutable(.{
        .name = "generate",
        .root_module = b.createModule(.{
            .root_source_file = b.path("template/generate.zig"),
            .target = target,
            .optimize = .ReleaseSafe,
        }),
    });
    const run_generate = b.addRunArtifact(generate_exe);
    run_generate.setCwd(b.path(""));
    generate.dependOn(&run_generate.step);

    // Tests for util.zig
    {
        const test_util = b.step("test_util", "Run tests in util.zig");
        const cmd = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/util.zig"),
                .target = target,
                .optimize = mode,
            }),
        });
        test_util.dependOn(&cmd.step);
    }

    // aoc-mcp: MCP server + CLI for adventofcode.com — a Zig port of
    // github.com/mazharenko/aoc-mcp (stdio MCP, HTTP submission).
    {
        const exe = b.addExecutable(.{
            .name = "aoc-mcp",
            .root_module = b.createModule(.{
                .root_source_file = b.path("tools/aoc-mcp/main.zig"),
                .target = target,
                .optimize = mode,
            }),
        });
        const install = b.addInstallArtifact(exe, .{});
        const step = b.step("aoc-mcp", "Build the Advent of Code MCP server/CLI");
        step.dependOn(&install.step);
    }

    // One exe + steps per (year, day). Steps:
    //   zig build 2015_03          run that day (`-- args` pass through)
    //   zig build install_2015_03  install the binary to zig-out/bin
    //   zig build test_2015_03     run tests in that day's file
    //   zig build run_2015         run every day of one year
    //   zig build test_2015        run tests for one year
    var year: u32 = first_year;
    while (year <= last_year) : (year += 1) {
        const year_str = b.fmt("{d}", .{year});
        const run_year = b.step(
            b.fmt("run_{s}", .{year_str}),
            b.fmt("Run all days of {d}", .{year}),
        );
        const test_year = b.step(
            b.fmt("test_{s}", .{year_str}),
            b.fmt("Run tests for all days of {d}", .{year}),
        );

        var day: u32 = 1;
        while (day <= 25) : (day += 1) {
            const day_str = b.fmt("day{d:0>2}", .{day});
            const id = b.fmt("{s}_{d:0>2}", .{ year_str, day });
            const zig_file = b.fmt("src/{s}/{s}.zig", .{ year_str, day_str });

            const wants_zom = dayWantsZom(b, zom_marker, zig_file);

            const mod = b.createModule(.{
                .root_source_file = b.path(zig_file),
                .target = target,
                .optimize = mode,
                .imports = if (wants_zom) &.{
                    .{ .name = "util", .module = util },
                    .{ .name = "zom", .module = zom },
                } else &.{
                    .{ .name = "util", .module = util },
                },
            });

            const exe = b.addExecutable(.{
                .name = id,
                .root_module = mod,
            });

            const install_cmd = b.addInstallArtifact(exe, .{});
            {
                const step = b.step(
                    b.fmt("install_{s}", .{id}),
                    b.fmt("Install {s} to zig-out/bin", .{id}),
                );
                step.dependOn(&install_cmd.step);
                install_all.dependOn(&install_cmd.step);
            }

            const run_cmd = b.addRunArtifact(exe);
            run_cmd.addPassthruArgs();
            {
                const step = b.step(id, b.fmt("Run {s} {s}", .{ year_str, day_str }));
                step.dependOn(&run_cmd.step);
                run_all.dependOn(&run_cmd.step);
                run_year.dependOn(&run_cmd.step);
            }

            {
                const run_tests = b.addTest(.{ .root_module = mod });
                const step = b.step(
                    b.fmt("test_{s}", .{id}),
                    b.fmt("Run tests in src/{s}/{s}.zig", .{ year_str, day_str }),
                );
                step.dependOn(&run_tests.step);
                test_year.dependOn(&run_tests.step);
            }
        }
    }

    // All tests across all years via src/test_all.zig
    const test_step = b.step("test", "Run all tests in all years");
    const all_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/test_all.zig"),
            .target = target,
            .optimize = mode,
            .imports = &.{
                .{ .name = "util", .module = util },
                .{ .name = "zom", .module = zom },
            },
        }),
    });
    const run_all_tests = b.addRunArtifact(all_tests);
    test_step.dependOn(&run_all_tests.step);
}

/// True when the day's source contains an uncommented `@import("zom")`,
/// meaning that day opts into the zom runtime (and its vendored SQLite).
/// Comment lines are skipped so the template's commented-out import hint
/// does not count as opting in.
fn dayWantsZom(b: *std.Build, zom_marker: []const u8, zig_file: []const u8) bool {
    const sub = b.root.joinString(b.allocator, zig_file) catch |err| {
        std.debug.print("zom opt-in scan: path join failed for {s}: {any}\n", .{ zig_file, err });
        return false;
    };
    const src = b.root.root_dir.handle.readFileAlloc(
        b.graph.io,
        sub,
        b.allocator,
        .limited(1 << 20),
    ) catch |err| {
        std.debug.print("zom opt-in scan: read failed for {s}: {any}\n", .{ sub, err });
        return false;
    };
    var it = std.mem.splitScalar(u8, src, '\n');
    while (it.next()) |line| {
        const t = std.mem.trim(u8, line, " \t");
        if (t.len != 0 and !std.mem.startsWith(u8, t, "//") and
            std.mem.indexOf(u8, t, zom_marker) != null)
        {
            return true;
        }
    }
    return false;
}
