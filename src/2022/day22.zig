const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day22.txt");

const face_size = 50;

var map: [220][220]u8 = @splat(@splat(' '));
var map_w: usize = 0;
var map_h: usize = 0;

const V3 = [3]i32;

const Face = struct {
    net_x: i32, // top-left in net coords
    net_y: i32,
    origin: V3, // world position of local (0,0)
    u: V3, // world vector of local +x
    v: V3, // world vector of local +y
};

var faces: List(Face) = .empty;
var face_at = Map([2]i32, usize).init(std.heap.page_allocator); // net cell (x/50, y/50) -> face idx

fn add(a: V3, b: V3) V3 {
    return .{ a[0] + b[0], a[1] + b[1], a[2] + b[2] };
}
fn dot(a: V3, b: V3) i32 {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}
fn sub(a: V3, b: V3) V3 {
    return .{ a[0] - b[0], a[1] - b[1], a[2] - b[2] };
}
fn neg(a: V3) V3 {
    return .{ -a[0], -a[1], -a[2] };
}

fn addFace(net_x: i32, net_y: i32, origin: V3, u: V3, v: V3) !void {
    try faces.append(gpa, .{ .net_x = net_x, .net_y = net_y, .origin = origin, .u = u, .v = v });
    try face_at.put(.{ net_x, net_y }, faces.items.len - 1);
}

/// Fold a new face adjacent to face `fi` in net direction `dir` (0=R,1=D,2=L,3=U).
fn foldNeighbor(fi: usize, dir: u8) !void {
    const f = faces.items[fi];
    const deltas = [4][2]i32{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } };
    const nx = f.net_x + deltas[dir][0];
    const ny = f.net_y + deltas[dir][1];
    if (face_at.contains(.{ nx, ny })) return;
    // check there's actually a face in the map there
    const px = nx * face_size;
    const py = ny * face_size;
    if (py < 0 or px < 0 or py >= map_h or px + face_size > map_w) return;
    if (map[@intCast(py)][@intCast(px)] == ' ') return;

    const f_normal = normalOf(f);
    var n: V3 = undefined;
    var u: V3 = undefined;
    var v: V3 = f.v;
    switch (dir) {
        0 => { // neighbor to the right
            n = f.u;
            u = neg(f_normal);
            v = f.v;
        },
        2 => { // left
            n = neg(f.u);
            u = f_normal;
            v = f.v;
        },
        1 => { // down
            n = f.v;
            v = neg(f_normal);
            u = f.u;
        },
        else => { // up
            n = neg(f.v);
            v = f_normal;
            u = f.u;
        },
    }
    // world origin of the new face: fold around the shared edge
    const o = foldOrigin(f, dir);
    try addFace(nx, ny, o, u, v);
}

fn foldOrigin(f: Face, dir: u8) V3 {
    // A's edge endpoints in world space; the neighbor's origin folds around it.
    // cube geometry: origin_B = edge_start + (edge_end - edge_start direction stays)
    // Simpler: origin_B such that shared edge coincides.
    const fx: V3 = f.origin;
    const fu = f.u;
    const fv = f.v;
    return switch (dir) {
        0 => add(fx, vec(fu, face_size)), // shared edge = A's right column
        2 => fx,
        1 => add(fx, vec(fv, face_size)),
        else => fx,
    };
}

fn normalOf(f: Face) V3 {
    // n = u x v
    return .{
        f.u[1] * f.v[2] - f.u[2] * f.v[1],
        f.u[2] * f.v[0] - f.u[0] * f.v[2],
        f.u[0] * f.v[1] - f.u[1] * f.v[0],
    };
}

// extend Face with a normal accessor via a helper on the struct value
const FaceExt = struct {
    fn normal(f: Face) V3 {
        return normalOf(f);
    }
};

pub fn main() !void {
    // parse map + path
    var path: []const u8 = "";
    {
        var lines = splitSca(u8, data, '\n');
        while (lines.next()) |line_raw| {
            const line = trimEnd(u8, line_raw, " \r");
            if (line.len == 0) {
                // path follows
                path = trim(u8, lines.next() orelse "", " \r");
                break;
            }
            if (line.len > map_w) map_w = line.len;
            @memcpy(map[map_h][0..line.len], line);
            map_h += 1;
        }
    }

    // ---- part 1: flat wrap ----
    {
        var x: usize = 0;
        var y: usize = 0;
        while (map[0][x] == ' ') x += 1;
        var dir: u8 = 0; // R D L U
        const dx = [4]i32{ 1, 0, -1, 0 };
        const dy = [4]i32{ 0, 1, 0, -1 };

        var i: usize = 0;
        while (i < path.len) {
            if (path[i] == 'L' or path[i] == 'R') {
                dir = (dir + (if (path[i] == 'R') @as(u8, 1) else 3)) % 4;
                i += 1;
                continue;
            }
            var steps: u32 = 0;
            while (i < path.len and path[i] >= '0' and path[i] <= '9') {
                steps = steps * 10 + (path[i] - '0');
                i += 1;
            }
            for (0..steps) |_| {
                var nx = @as(i32, @intCast(x)) + dx[dir];
                var ny = @as(i32, @intCast(y)) + dy[dir];
                // wrap
                if (nx >= map_w or (ny >= 0 and ny < map_h and nx >= 0 and nx < map_w and map[@intCast(ny)][@intCast(nx)] == ' ')) {
                    // scan from the other side
                    if (dx[dir] != 0) {
                        nx = if (dx[dir] > 0) 0 else @as(i32, @intCast(map_w)) - 1;
                        while (map[@intCast(ny)][@intCast(nx)] == ' ') {
                            nx += dx[dir];
                        }
                    } else {
                        ny = if (dy[dir] > 0) 0 else @as(i32, @intCast(map_h)) - 1;
                        while (map[@intCast(ny)][@intCast(nx)] == ' ') {
                            ny += dy[dir];
                        }
                    }
                }
                if (ny < 0 or ny >= map_h or nx < 0 or nx >= map_w) break;
                const c = map[@intCast(ny)][@intCast(nx)];
                if (c == '#') break;
                x = @intCast(nx);
                y = @intCast(ny);
            }
        }
        const facing: u64 = switch (dir) {
            0 => 0,
            1 => 1,
            2 => 2,
            else => 3,
        };
        print("part 1: {d}\n", .{1000 * (y + 1) + 4 * (x + 1) + facing});
    }

    // ---- part 2: cube ----
    // discover faces
    {
        const ny_faces = (map_h + face_size - 1) / face_size;
        const nx_faces = (map_w + face_size - 1) / face_size;
        var found = false;
        for (0..ny_faces) |fy| {
            for (0..nx_faces) |fx| {
                if (map[fy * face_size][fx * face_size] != ' ') {
                    if (!found) {
                        try addFace(@intCast(fx), @intCast(fy), .{ 0, 0, 0 }, .{ 1, 0, 0 }, .{ 0, 1, 0 });
                        found = true;
                    }
                }
            }
        }
        // BFS-fold the whole net
        var changed = true;
        while (changed) {
            changed = false;
            for (0..faces.items.len) |fi| {
                for (0..4) |dir| {
                    const before = faces.items.len;
                    try foldNeighbor(fi, @intCast(dir));
                    if (faces.items.len > before) changed = true;
                }
            }
        }
        if (faces.items.len != 6) {
            print("net analysis failed: {d} faces\n", .{faces.items.len});
            return;
        }
    }

    // walk on the cube: state = face idx, local x, y, dir
    {
        // start: top-left open cell of the first face
        var fi: usize = 0;
        var lx: i32 = 0;
        var ly: i32 = 0;
        for (0..face_size) |yy| {
            for (0..face_size) |xx| {
                if (map[yy][xx] == '.') {
                    lx = @intCast(xx % face_size);
                    ly = @intCast(yy % face_size);
                    break;
                }
            }
        }
        var dir: u8 = 0;

        var i: usize = 0;
        while (i < path.len) {
            if (path[i] == 'L' or path[i] == 'R') {
                dir = (dir + (if (path[i] == 'R') @as(u8, 1) else 3)) % 4;
                i += 1;
                continue;
            }
            var steps: u32 = 0;
            while (i < path.len and path[i] >= '0' and path[i] <= '9') {
                steps = steps * 10 + (path[i] - '0');
                i += 1;
            }
            for (0..steps) |_| {
                const f = faces.items[fi];
                const deltas = [4][2]i32{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } };
                var nlx = lx + deltas[dir][0];
                var nly = ly + deltas[dir][1];
                var ndir = dir;
                var nfi = fi;
                if (nlx < 0 or nlx >= face_size or nly < 0 or nly >= face_size) {
                    // cross into the neighbor face
                    const nfi2 = face_at.get(.{ f.net_x + deltas[dir][0], f.net_y + deltas[dir][1] });
                    if (nfi2 == null) {
                        // not directly adjacent in the net — the net wraps;
                        // find the face sharing this world edge
                        nfi = try findAcross(fi, dir);
                    } else {
                        nfi = nfi2.?;
                    }
                    const nf = faces.items[nfi];
                    // world position of the cell we'd exit INTO (one past the edge)
                    const world = add(add(f.origin, vec(f.u, lx + deltas[dir][0])), vec(f.v, ly + deltas[dir][1]));
                    // project onto nf
                    const rel = sub(world, nf.origin);
                    nlx = @divTrunc(dot(rel, nf.u), 1);
                    nly = @divTrunc(dot(rel, nf.v), 1);
                    if (nlx < 0 or nlx >= face_size or nly < 0 or nly >= face_size) {
                        // projection outside — try the shared-edge midpoint trick
                        // recompute using the edge cell
                        const edge_world = add(add(f.origin, vec(f.u, lx)), vec(f.v, ly));
                        const rel2 = sub(edge_world, nf.origin);
                        nlx = @divTrunc(dot(rel2, nf.u), 1);
                        nly = @divTrunc(dot(rel2, nf.v), 1);
                    }
                    // new direction: travel vector t along the old dir
                    const t = dirVecOnFace(f, dir);
                    const along_u = dot(t, nf.u);
                    const along_v = dot(t, nf.v);
                    if (along_u > 0) {
                        ndir = 0;
                    } else if (along_u < 0) {
                        ndir = 2;
                    } else if (along_v > 0) {
                        ndir = 1;
                    } else {
                        ndir = 3;
                    }
                }
                // map back to net coords to check the cell
                const nf = faces.items[nfi];
                const mx = nf.net_x * face_size + nlx;
                const my = nf.net_y * face_size + nly;
                if (mx < 0 or my < 0 or my >= map_h or mx >= map_w) break;
                if (map[@intCast(my)][@intCast(mx)] == '#') break;
                fi = nfi;
                lx = nlx;
                ly = nly;
                dir = ndir;
            }
        }
        // final coords
        const f = faces.items[fi];
        const fx = f.net_x * face_size + lx;
        const fy = f.net_y * face_size + ly;
        const facing: u64 = switch (dir) {
            0 => 0,
            1 => 1,
            2 => 2,
            else => 3,
        };
        print("part 2: {d}\n", .{1000 * (@as(u64, @intCast(fy)) + 1) + 4 * (@as(u64, @intCast(fx)) + 1) + facing});
    }
}

fn vec(base: V3, k: i32) V3 {
    return .{ base[0] * k, base[1] * k, base[2] * k };
}

fn dirVecOnFace(f: Face, dir: u8) V3 {
    return switch (dir) {
        0 => f.u,
        1 => f.v,
        2 => neg(f.u),
        else => neg(f.v),
    };
}

/// Find the face whose shared world edge is the one we're exiting across.
fn findAcross(fi: usize, dir: u8) !usize {
    const f = faces.items[fi];
    const deltas = [4][2]i32{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } };
    const exit_nx = f.net_x + deltas[dir][0];
    const exit_ny = f.net_y + deltas[dir][1];
    _ = exit_nx;
    _ = exit_ny;
    // the world position just past the edge in the exit direction
    // walk in a spiral: for each OTHER face, check if it shares the edge
    for (faces.items, 0..) |*nf, idx| {
        if (idx == fi) continue;
        // does nf contain the world edge? compute the two edge endpoints of f
        var edge_min: V3 = f.origin;
        var edge_max: V3 = f.origin;
        switch (dir) {
            0 => {
                edge_min = add(f.origin, vec(f.u, face_size));
                edge_max = add(edge_min, vec(f.v, face_size - 1));
            },
            2 => {
                edge_max = add(f.origin, vec(f.v, face_size - 1));
            },
            1 => {
                edge_min = add(f.origin, vec(f.v, face_size));
                edge_max = add(edge_min, vec(f.u, face_size - 1));
            },
            else => {
                edge_max = add(f.origin, vec(f.u, face_size - 1));
            },
        }
        // is edge_min on nf's boundary?
        const rel = sub(edge_min, nf.origin);
        const ru = dot(rel, nf.u);
        const rv = dot(rel, nf.v);
        if (ru < 0 or ru > face_size or rv < 0 or rv > face_size) continue;
        const rel2 = sub(edge_max, nf.origin);
        const ru2 = dot(rel2, nf.u);
        const rv2 = dot(rel2, nf.v);
        if (ru2 < 0 or ru2 > face_size or rv2 < 0 or rv2 > face_size) continue;
        return idx;
    }
    return error.NoNeighborFace;
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
const trimEnd = std.mem.trimEnd;
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
