//! aoc-mcp — a Zig reimplementation of mazharenko/aoc-mcp
//! (https://github.com/mazharenko/aoc-mcp), an MCP server for
//! adventofcode.com, plus a plain CLI mode for direct use.
//!
//! Modes:
//!   aoc-mcp                                    MCP server over stdio (JSON-RPC)
//!   aoc-mcp serve                              same, explicit
//!   aoc-mcp progress <year>                    print star count for a year
//!   aoc-mcp input <year> <day>                 print the personal puzzle input
//!   aoc-mcp submit <year> <day> <part> <ans>   submit an answer (waits out rate limits)
//!
//! Session resolution order: --session flag, $AOC_SESSION, $SESSION_COOKIE,
//! or a `.aoc_session` file in the cwd. The cookie is a secret — it is never
//! written anywhere by this program and must not be committed.

const std = @import("std");

const base_url = "https://adventofcode.com";
const user_agent = "aoc-mcp-zig/0.1.0 (+via github.com/mazharenko/aoc-mcp by mazharenko.a@gmail.com; zig port)";

// ---------------------------------------------------------------------------
// Session
// ---------------------------------------------------------------------------

fn resolveSession(alloc: std.mem.Allocator, io: std.Io, env: *std.process.Environ.Map, flag: ?[]const u8) ![]const u8 {
    // Always returns an allocation owned by the caller.
    if (flag) |s| return alloc.dupe(u8, s);
    if (env.get("AOC_SESSION")) |s| return alloc.dupe(u8, s);
    if (env.get("SESSION_COOKIE")) |s| return alloc.dupe(u8, s);
    if (std.Io.Dir.cwd().readFileAlloc(io, ".aoc_session", alloc, .limited(4096))) |raw| {
        defer alloc.free(raw);
        return alloc.dupe(u8, std.mem.trimEnd(u8, raw, " \n\r\t"));
    } else |_| {}
    std.debug.print("error: no session — pass --session, set AOC_SESSION/SESSION_COOKIE, or create .aoc_session\n", .{});
    return error.NoSession;
}

// ---------------------------------------------------------------------------
// HTTP client
// ---------------------------------------------------------------------------

const Http = struct {
    alloc: std.mem.Allocator,
    io: std.Io,
    session: []const u8,

    fn fetch(
        self: *Http,
        method: std.http.Method,
        path: []const u8,
        payload: ?[]const u8,
        body: *std.Io.Writer.Allocating,
    ) !std.http.Status {
        var client = std.http.Client{
            .allocator = self.alloc,
            .io = self.io,
        };
        defer client.deinit();

        var url_buf: [256]u8 = undefined;
        const url = try std.fmt.bufPrint(&url_buf, "{s}{s}", .{ base_url, path });

        var cookie_buf: [512]u8 = undefined;
        const cookie = try std.fmt.bufPrint(&cookie_buf, "session={s}", .{self.session});

        const res = try client.fetch(.{
            .location = .{ .url = url },
            .method = method,
            .payload = payload,
            .response_writer = &body.writer,
            .headers = .{
                .user_agent = .{ .override = user_agent },
                .content_type = if (payload != null)
                    .{ .override = "application/x-www-form-urlencoded" }
                else
                    .default,
            },
            .extra_headers = &.{
                .{ .name = "Cookie", .value = cookie },
            },
        });
        return res.status;
    }
};

// ---------------------------------------------------------------------------
// AoC operations
// ---------------------------------------------------------------------------

fn ensureOk(status: std.http.Status) !void {
    const code = @backingInt(status);
    if (code >= 400) {
        std.debug.print("HTTP {d} from adventofcode.com (bad session? day locked?)\n", .{code});
        return error.HttpError;
    }
}

const SubmissionResult = union(enum) {
    correct,
    incorrect,
    too_high,
    too_low,
    wrong_level,
    too_recent: u32, // seconds

    fn name(self: SubmissionResult) []const u8 {
        return switch (self) {
            .correct => "Correct",
            .incorrect => "Incorrect",
            .too_high => "TooHigh",
            .too_low => "TooLow",
            .wrong_level => "WrongLevel",
            .too_recent => "TooRecently",
        };
    }
};

fn loadInput(h: *Http, alloc: std.mem.Allocator, year: u32, day: u32) ![]u8 {
    var path_buf: [64]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "/{d}/day/{d}/input", .{ year, day });
    var body: std.Io.Writer.Allocating = .init(alloc);
    defer body.deinit();
    const status = try h.fetch(.GET, path, null, &body);
    try ensureOk(status);
    return body.toOwnedSlice();
}

fn submitAnswer(h: *Http, alloc: std.mem.Allocator, year: u32, day: u32, part: u32, answer: []const u8) !SubmissionResult {
    var path_buf: [64]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "/{d}/day/{d}/answer", .{ year, day });
    // url-encode the answer: answers like SNAFU strings contain '=' and
    // must not appear raw in an application/x-www-form-urlencoded body
    var form_buf: [256]u8 = undefined;
    var fb: usize = 0;
    fb += (std.fmt.bufPrint(form_buf[fb..], "level={d}&answer=", .{part}) catch unreachable).len;
    for (answer) |c| {
        const safe = (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '-' or c == '_' or c == '.';
        if (safe) {
            form_buf[fb] = c;
            fb += 1;
        } else {
            fb += (std.fmt.bufPrint(form_buf[fb..], "%{X:0>2}", .{c}) catch unreachable).len;
        }
    }
    const form = form_buf[0..fb];

    var body: std.Io.Writer.Allocating = .init(alloc);
    defer body.deinit();
    const status = try h.fetch(.POST, path, form, &body);
    try ensureOk(status);
    const content = body.written();

    if (std.mem.find(u8, content, "That's the right answer!") != null) return .correct;
    if (std.mem.find(u8, content, "too high") != null) return .too_high;
    if (std.mem.find(u8, content, "too low") != null) return .too_low;
    if (std.mem.find(u8, content, "That's not the right answer") != null) return .incorrect;
    if (std.mem.find(u8, content, "You don't seem to be solving the right level.") != null) return .wrong_level;

    // "You have 4m 59s left to wait" / "You have 59s left"
    if (std.mem.find(u8, content, "You have ")) |i| {
        const rest = content[i + "You have ".len ..];
        var minutes: u32 = 0;
        var seconds: u32 = 0;
        var pos: usize = 0;
        while (pos < rest.len) {
            if (rest[pos] >= '0' and rest[pos] <= '9') {
                const n = parseLeadingInt(rest, &pos);
                while (pos < rest.len and rest[pos] == ' ') pos += 1;
                if (pos < rest.len and rest[pos] == 'm') {
                    minutes = n;
                    pos += 1;
                } else if (pos < rest.len and rest[pos] == 's') {
                    seconds = n;
                    pos += 1;
                } else break;
            } else if (rest[pos] == ' ') {
                pos += 1;
            } else break;
        }
        if (std.mem.find(u8, rest, "left") != null) {
            // clamp: a misparse or an aggressive limit must not stall for
            // hours — re-posting early just yields another too_recent
            return .{ .too_recent = @min(minutes * 60 + seconds, 600) };
        }
    }
    std.debug.print("unrecognized submission response ({d} bytes)\n", .{content.len});
    return error.UnrecognizedResponse;
}

fn parseLeadingInt(s: []const u8, pos: *usize) u32 {
    const start = pos.*;
    while (pos.* < s.len and s[pos.*] >= '0' and s[pos.*] <= '9') pos.* += 1;
    return std.fmt.parseInt(u32, s[start..pos.*], 10) catch 0;
}

const Progress = struct {
    stars: u32,
    // solved[i] = {day, part}
    solved: []const [2]u32,
};

fn getProgress(h: *Http, alloc: std.mem.Allocator, year: u32) !Progress {
    var path_buf: [16]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "/{d}", .{year});
    var body: std.Io.Writer.Allocating = .init(alloc);
    defer body.deinit();
    const status = try h.fetch(.GET, path, null, &body);
    try ensureOk(status);
    const html = body.written();

    // Mirror of the original's regex:
    //   aria-label="Day (\d+)(, ((one star)|(two stars))?)"?
    var solved: std.ArrayList([2]u32) = .empty;
    errdefer solved.deinit(alloc);

    var pos: usize = 0;
    while (std.mem.findPos(u8, html, pos, "aria-label=\"Day ")) |i| {
        const after = html[i + "aria-label=\"Day ".len ..];
        var p: usize = 0;
        if (after.len == 0 or after[0] < '0' or after[0] > '9') {
            pos = i + 1;
            continue;
        }
        const day = parseLeadingInt(after, &p);
        while (p < after.len and after[p] == ' ') p += 1;
        var stars: u32 = 0;
        if (std.mem.startsWith(u8, after[p..], ", one star")) {
            stars = 1;
            p += ", one star".len;
        } else if (std.mem.startsWith(u8, after[p..], ", two stars")) {
            stars = 2;
            p += ", two stars".len;
        }
        var part: u32 = 1;
        while (part <= stars) : (part += 1) {
            try solved.append(alloc, .{ day, part });
        }
        pos = i + 1;
    }
    return .{ .stars = @intCast(solved.items.len), .solved = try solved.toOwnedSlice(alloc) };
}

// ---------------------------------------------------------------------------
// JSON output helpers (hand-rolled; fixed shapes, escaped strings)
// ---------------------------------------------------------------------------

fn jsonEscape(w: *std.Io.Writer, s: []const u8) !void {
    for (s) |c| {
        switch (c) {
            '"' => try w.writeAll("\\\""),
            '\\' => try w.writeAll("\\\\"),
            '\n' => try w.writeAll("\\n"),
            '\r' => try w.writeAll("\\r"),
            '\t' => try w.writeAll("\\t"),
            else => {
                if (c < 0x20) {
                    try w.print("\\u{x:0>4}", .{c});
                } else {
                    try w.writeByte(c);
                }
            },
        }
    }
}

fn writeJsonId(w: *std.Io.Writer, id: std.json.Value) !void {
    switch (id) {
        .integer => |n| try w.print("{d}", .{n}),
        .float => |f| try w.print("{d}", .{f}),
        .number_string => |s| try w.writeAll(s),
        .string => |s| {
            try w.writeByte('"');
            try jsonEscape(w, s);
            try w.writeByte('"');
        },
        .bool => |b| try w.writeAll(if (b) "true" else "false"),
        .null => try w.writeAll("null"),
        else => try w.writeAll("null"),
    }
}

// ---------------------------------------------------------------------------
// MCP server (stdio, newline-delimited JSON-RPC 2.0)
// ---------------------------------------------------------------------------

const tools_list_json =
    "{\"tools\":[" ++
    "{\"name\":\"GetAocProgress\",\"description\":\"Get Advent of Code progress summary, namely, number of acquired stars.\",\"inputSchema\":{\"type\":\"object\",\"properties\":{\"year\":{\"type\":\"integer\",\"description\":\"AoC event year\"}},\"required\":[\"year\"]}}," ++
    "{\"name\":\"SubmitAnswer\",\"description\":\"Submit an answer for a part. Returns if the answer was correct or incorrect or too high or too low. Waits out rate limits.\",\"inputSchema\":{\"type\":\"object\",\"properties\":{\"answer\":{\"type\":\"string\"},\"year\":{\"type\":\"integer\"},\"day\":{\"type\":\"integer\"},\"part\":{\"type\":\"integer\"}},\"required\":[\"answer\",\"year\",\"day\",\"part\"]}}," ++
    "{\"name\":\"GetInputResource\",\"description\":\"Retrieves a puzzle input\",\"inputSchema\":{\"type\":\"object\",\"properties\":{\"year\":{\"type\":\"integer\"},\"day\":{\"type\":\"integer\"}},\"required\":[\"year\",\"day\"]}}" ++
    "]}";

const resource_templates_json =
    "{\"resourceTemplates\":[" ++
    "{\"uriTemplate\":\"aocinput://{year}/{day}\",\"name\":\"Puzzle input resource\",\"mimeType\":\"text/plain\",\"description\":\"Retrieves a puzzle input\"}" ++
    "]}";

const Mcp = struct {
    alloc: std.mem.Allocator,
    io: std.Io,
    http: *Http,
    out: *std.Io.File.Writer,

    fn send(self: *Mcp, s: []const u8) !void {
        try self.out.interface.writeAll(s);
        try self.out.interface.writeByte('\n');
        try self.out.interface.flush();
    }

    fn sendResult(self: *Mcp, id: std.json.Value, result: []const u8) !void {
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        defer buf.deinit();
        const w = &buf.writer;
        try w.writeAll("{\"jsonrpc\":\"2.0\",\"id\":");
        try writeJsonId(w, id);
        try w.writeAll(",\"result\":");
        try w.writeAll(result);
        try w.writeAll("}");
        try self.send(buf.written());
    }

    fn sendError(self: *Mcp, id: std.json.Value, code: i32, message: []const u8) !void {
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        defer buf.deinit();
        const w = &buf.writer;
        try w.writeAll("{\"jsonrpc\":\"2.0\",\"id\":");
        try writeJsonId(w, id);
        try w.print(",\"error\":{{\"code\":{d},\"message\":\"", .{code});
        try jsonEscape(w, message);
        try w.writeAll("\"}}");
        try self.send(buf.written());
    }

    fn sendNotification(self: *Mcp, method: []const u8, params: []const u8) !void {
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        defer buf.deinit();
        const w = &buf.writer;
        try w.writeAll("{\"jsonrpc\":\"2.0\",\"method\":\"");
        try w.writeAll(method);
        try w.writeAll("\",\"params\":");
        try w.writeAll(params);
        try w.writeAll("}");
        try self.send(buf.written());
    }

    fn textResult(alloc: std.mem.Allocator, text: []const u8) ![]u8 {
        var buf: std.Io.Writer.Allocating = .init(alloc);
        defer buf.deinit();
        const w = &buf.writer;
        try w.writeAll("{\"content\":[{\"type\":\"text\",\"text\":\"");
        try jsonEscape(w, text);
        try w.writeAll("\"}],\"isError\":false}");
        return buf.toOwnedSlice();
    }

    fn textError(alloc: std.mem.Allocator, msg: []const u8) ![]u8 {
        var buf: std.Io.Writer.Allocating = .init(alloc);
        defer buf.deinit();
        const w = &buf.writer;
        try w.writeAll("{\"content\":[{\"type\":\"text\",\"text\":\"");
        try jsonEscape(w, msg);
        try w.writeAll("\"}],\"isError\":true}");
        return buf.toOwnedSlice();
    }

    fn argInt(args: std.json.ObjectMap, name: []const u8) !i64 {
        const v = args.get(name) orelse return error.MissingArgument;
        return switch (v) {
            .integer => |n| n,
            .float => |f| @intFromFloat(f),
            .number_string, .string => |s| std.fmt.parseInt(i64, s, 10) catch error.BadArgument,
            else => error.BadArgument,
        };
    }

    fn argStr(args: std.json.ObjectMap, name: []const u8) ![]const u8 {
        const v = args.get(name) orelse return error.MissingArgument;
        return switch (v) {
            .string => |s| s,
            .number_string => |s| s,
            else => error.BadArgument,
        };
    }

    /// Handles one JSON-RPC message. Returns false when the loop should stop.
    fn handleMessage(self: *Mcp, line: []const u8) !bool {
        const parsed = std.json.parseFromSlice(std.json.Value, self.alloc, line, .{}) catch {
            std.debug.print("ignoring malformed JSON-RPC line\n", .{});
            return true;
        };
        defer parsed.deinit();
        const root = parsed.value;
        if (root != .object) return true;
        const obj = root.object;

        const method: []const u8 = if (obj.get("method")) |m| switch (m) {
            .string => |s| s,
            else => return true,
        } else "";
        const id: std.json.Value = obj.get("id") orelse .null;

        if (std.mem.eql(u8, method, "initialize")) {
            var proto: []const u8 = "2025-06-18";
            if (obj.get("params")) |p| {
                if (p == .object) {
                    if (p.object.get("protocolVersion")) |v| {
                        if (v == .string) proto = v.string; // echo the client's version
                    }
                }
            }
            var buf: std.Io.Writer.Allocating = .init(self.alloc);
            defer buf.deinit();
            const w = &buf.writer;
            try w.writeAll("{\"protocolVersion\":\"");
            try w.writeAll(proto);
            try w.writeAll("\",\"capabilities\":{\"tools\":{},\"resources\":{}},\"serverInfo\":{\"name\":\"aoc-mcp-zig\",\"version\":\"0.1.0\"}}");
            try self.sendResult(id, buf.written());
            return true;
        }
        if (std.mem.eql(u8, method, "ping")) {
            try self.sendResult(id, "{}");
            return true;
        }
        if (std.mem.eql(u8, method, "tools/list")) {
            try self.sendResult(id, tools_list_json);
            return true;
        }
        if (std.mem.eql(u8, method, "resources/templates/list")) {
            try self.sendResult(id, resource_templates_json);
            return true;
        }
        if (std.mem.eql(u8, method, "resources/list")) {
            try self.sendResult(id, "{\"resources\":[]}");
            return true;
        }
        if (std.mem.eql(u8, method, "resources/read")) {
            const params = obj.get("params") orelse return error.BadParams;
            if (params != .object) return error.BadParams;
            const uri = argStr(params.object, "uri") catch {
                try self.sendError(id, -32602, "missing uri");
                return true;
            };
            // aocinput://{year}/{day}
            if (!std.mem.startsWith(u8, uri, "aocinput://")) {
                try self.sendError(id, -32602, "unknown resource uri");
                return true;
            }
            const rest = uri["aocinput://".len..];
            const slash = std.mem.findScalar(u8, rest, '/') orelse {
                try self.sendError(id, -32602, "bad uri");
                return true;
            };
            const year = std.fmt.parseInt(u32, rest[0..slash], 10) catch {
                try self.sendError(id, -32602, "bad year");
                return true;
            };
            const day = std.fmt.parseInt(u32, rest[slash + 1 ..], 10) catch {
                try self.sendError(id, -32602, "bad day");
                return true;
            };
            const input = loadInput(self.http, self.alloc, year, day) catch |e| {
                const r = try textError(self.alloc, @errorName(e));
                try self.sendResult(id, r);
                self.alloc.free(r);
                return true;
            };
            defer self.alloc.free(input);
            var buf: std.Io.Writer.Allocating = .init(self.alloc);
            defer buf.deinit();
            const w = &buf.writer;
            try w.writeAll("{\"contents\":[{\"uri\":\"");
            try jsonEscape(w, uri);
            try w.writeAll("\",\"mimeType\":\"text/plain\",\"text\":\"");
            try jsonEscape(w, input);
            try w.writeAll("\"}]}");
            try self.sendResult(id, buf.written());
            return true;
        }
        if (std.mem.eql(u8, method, "tools/call")) {
            const params = obj.get("params") orelse return error.BadParams;
            if (params != .object) return error.BadParams;
            const name = argStr(params.object, "name") catch {
                try self.sendError(id, -32602, "missing tool name");
                return true;
            };
            const args: std.json.ObjectMap = if (params.object.get("arguments")) |a|
                (if (a == .object) a.object else .{})
            else
                .{};

            var progress_token: ?std.json.Value = null;
            if (params.object.get("_meta")) |meta| {
                if (meta == .object) {
                    if (meta.object.get("progressToken")) |pt| progress_token = pt;
                }
            }

            if (std.mem.eql(u8, name, "GetAocProgress")) {
                const year = argInt(args, "year") catch {
                    try self.sendError(id, -32602, "missing year");
                    return true;
                };
                const prog = getProgress(self.http, self.alloc, @intCast(year)) catch |e| {
                    const r = try textError(self.alloc, @errorName(e));
                    try self.sendResult(id, r);
                    self.alloc.free(r);
                    return true;
                };
                defer self.alloc.free(prog.solved);
                var buf: std.Io.Writer.Allocating = .init(self.alloc);
                defer buf.deinit();
                const w = &buf.writer;
                try w.writeAll("{\"content\":[{\"type\":\"text\",\"text\":\"");
                try w.print("{d} stars", .{prog.stars});
                try w.writeAll("\"}],\"isError\":false,\"structuredContent\":{\"Stars\":");
                try w.print("{d}", .{prog.stars});
                try w.writeAll(",\"Solved\":[");
                for (prog.solved, 0..) |s, i| {
                    if (i > 0) try w.writeAll(",");
                    try w.print("{{\"Day\":{d},\"Part\":{d}}}", .{ s[0], s[1] });
                }
                try w.writeAll("]}}");
                try self.sendResult(id, buf.written());
                return true;
            }
            if (std.mem.eql(u8, name, "GetInputResource")) {
                const year = argInt(args, "year") catch {
                    try self.sendError(id, -32602, "missing year");
                    return true;
                };
                const day = argInt(args, "day") catch {
                    try self.sendError(id, -32602, "missing day");
                    return true;
                };
                const input = loadInput(self.http, self.alloc, @intCast(year), @intCast(day)) catch |e| {
                    const r = try textError(self.alloc, @errorName(e));
                    try self.sendResult(id, r);
                    self.alloc.free(r);
                    return true;
                };
                defer self.alloc.free(input);
                var buf: std.Io.Writer.Allocating = .init(self.alloc);
                defer buf.deinit();
                const w = &buf.writer;
                try w.writeAll("{\"content\":[{\"type\":\"text\",\"text\":\"");
                try jsonEscape(w, input);
                try w.writeAll("\"}],\"isError\":false}");
                try self.sendResult(id, buf.written());
                return true;
            }
            if (std.mem.eql(u8, name, "SubmitAnswer")) {
                const answer = argStr(args, "answer") catch {
                    try self.sendError(id, -32602, "missing answer");
                    return true;
                };
                const year = argInt(args, "year") catch {
                    try self.sendError(id, -32602, "missing year");
                    return true;
                };
                const day = argInt(args, "day") catch {
                    try self.sendError(id, -32602, "missing day");
                    return true;
                };
                const part = argInt(args, "part") catch {
                    try self.sendError(id, -32602, "missing part");
                    return true;
                };
                const result = self.submitWithRetry(@intCast(year), @intCast(day), @intCast(part), answer, progress_token) catch |e| {
                    const r = try textError(self.alloc, @errorName(e));
                    try self.sendResult(id, r);
                    self.alloc.free(r);
                    return true;
                };
                const r = try textResult(self.alloc, result.name());
                try self.sendResult(id, r);
                self.alloc.free(r);
                return true;
            }
            try self.sendError(id, -32602, "unknown tool");
            return true;
        }

        // Notifications (no id) and unknown methods are ignored; unknown
        // methods WITH an id get a standard error.
        if (id != .null and method.len > 0) {
            try self.sendError(id, -32601, "method not found");
        }
        return true;
    }

    fn submitWithRetry(self: *Mcp, year: u32, day: u32, part: u32, answer: []const u8, progress_token: ?std.json.Value) !SubmissionResult {
        while (true) {
            const result = try submitAnswer(self.http, self.alloc, year, day, part, answer);
            switch (result) {
                .too_recent => |total| {
                    var waited: u32 = 0;
                    while (waited < total) {
                        const slice: u32 = @min(1, total - waited);
                        if (progress_token) |pt| {
                            var buf: std.Io.Writer.Allocating = .init(self.alloc);
                            defer buf.deinit();
                            const w = &buf.writer;
                            try w.writeAll("{\"progress\":");
                            try w.print("{d}", .{waited});
                            try w.writeAll(",\"total\":");
                            try w.print("{d}", .{total});
                            try w.writeAll(",\"_meta\":{\"progressToken\":");
                            try writeJsonId(w, pt);
                            try w.writeAll("},\"message\":\"Answer given too recently. Waiting before another attempt\"}");
                            self.sendNotification("notifications/progress", buf.written()) catch {};
                        }
                        std.Io.sleep(self.io, std.Io.Duration.fromMilliseconds(@as(i64, slice) * 1000), .awake) catch {};
                        waited += slice;
                    }
                    continue;
                },
                else => return result,
            }
        }
    }
};

fn serve(alloc: std.mem.Allocator, io: std.Io, session: []const u8) !void {
    var http = Http{ .alloc = alloc, .io = io, .session = session };
    var out_buffer: [64 * 1024]u8 = undefined;
    var out: std.Io.File.Writer = .init(.stdout(), io, &out_buffer);

    var stdin_buffer: [1024 * 1024]u8 = undefined;
    var file_reader: std.Io.File.Reader = .init(.stdin(), io, &stdin_buffer);
    const stdin = &file_reader.interface;

    var mcp = Mcp{ .alloc = alloc, .io = io, .http = &http, .out = &out };

    while (true) {
        const line_inc = stdin.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                // Handle a final unterminated line, if any.
                const rest = stdin.buffer[stdin.seek..stdin.end];
                if (rest.len > 0) _ = try mcp.handleMessage(rest);
                break;
            },
            else => return err,
        };
        const line = std.mem.trimEnd(u8, line_inc, "\n\r");
        if (line.len == 0) continue;
        if (!try mcp.handleMessage(line)) break;
    }
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

fn runCli(
    alloc: std.mem.Allocator,
    io: std.Io,
    session: []const u8,
    cmd: []const u8,
    args: [][]const u8,
) !void {
    var http = Http{ .alloc = alloc, .io = io, .session = session };

    if (std.mem.eql(u8, cmd, "progress") and args.len == 1) {
        const year = try std.fmt.parseInt(u32, args[0], 10);
        const prog = try getProgress(&http, alloc, year);
        defer alloc.free(prog.solved);
        var stdout: std.Io.File.Writer = .init(.stdout(), io, &[_]u8{});
        try stdout.interface.print("{d} stars\n", .{prog.stars});
        try stdout.interface.flush();
        return;
    }
    if (std.mem.eql(u8, cmd, "input") and args.len == 2) {
        const year = try std.fmt.parseInt(u32, args[0], 10);
        const day = try std.fmt.parseInt(u32, args[1], 10);
        const input = try loadInput(&http, alloc, year, day);
        defer alloc.free(input);
        var stdout: std.Io.File.Writer = .init(.stdout(), io, &[_]u8{});
        try stdout.interface.writeAll(input);
        try stdout.interface.flush();
        return;
    }
    if (std.mem.eql(u8, cmd, "submit") and args.len == 4) {
        const year = try std.fmt.parseInt(u32, args[0], 10);
        const day = try std.fmt.parseInt(u32, args[1], 10);
        const part = try std.fmt.parseInt(u32, args[2], 10);
        const answer = args[3];

        var mcp_like = Mcp{ .alloc = alloc, .io = io, .http = &http, .out = undefined };
        const result = try mcp_like.submitWithRetry(year, day, part, answer, null);
        std.debug.print("{s}\n", .{result.name()});
        return;
    }
    std.debug.print(
        \\usage: aoc-mcp [--session <cookie>] [serve]
        \\       aoc-mcp progress <year>
        \\       aoc-mcp input <year> <day>
        \\       aoc-mcp submit <year> <day> <part> <answer>
        \\
    , .{});
    return error.Usage;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const alloc = init.gpa;

    var args_it = try std.process.Args.Iterator.initAllocator(init.minimal.args, alloc);
    defer args_it.deinit();
    _ = args_it.next(); // argv0

    var session_flag: ?[]const u8 = null;
    var rest: std.ArrayList([]const u8) = .empty;
    defer rest.deinit(alloc);

    while (args_it.next()) |a| {
        if (std.mem.eql(u8, a, "--session")) {
            session_flag = args_it.next() orelse return error.Usage;
        } else {
            try rest.append(alloc, a);
        }
    }

    const session = try resolveSession(alloc, io, init.environ_map, session_flag);
    defer alloc.free(session);

    if (rest.items.len == 0 or std.mem.eql(u8, rest.items[0], "serve")) {
        try serve(alloc, io, session);
        return;
    }
    const cmd = rest.items[0];
    try runCli(alloc, io, session, cmd, rest.items[1..]);
}
