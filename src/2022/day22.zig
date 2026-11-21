const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
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
        2 => add(fx, vec(normalOf(f), -face_size)), // left: back off along the normal
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
                // wrap: any off-map step, or a step into the void, restarts
                // from the opposite edge of the CURRENT row/column
                if (nx < 0 or nx >= map_w or ny < 0 or ny >= map_h or map[@intCast(ny)][@intCast(nx)] == ' ') {
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
        if (std.c.getenv("D22DBG") != null) {
            for (faces.items, 0..) |*g, gi| {
                print("face {d}: net=({d},{d}) origin={any} u={any} v={any} n={any}\n", .{ gi, g.net_x, g.net_y, g.origin, g.u, g.v, normalOf(g.*) });
            }
        }
        if (faces.items.len != 6) {
            print("net analysis failed: {d} faces\n", .{faces.items.len});
            return;
        }
    }

    // walk on the cube: cell centers in world space. Stepping off a face
    // rotates the overshoot cell and the heading 90 degrees about the
    // crossed edge (either sign — the correct one lands on a face).
    {
        const f0 = faces.items[0];
        var fi: usize = 0;
        var lx: i32 = 0;
        var ly: i32 = 0;
        {
            const row = f0.net_y * face_size;
            var k: i32 = 0;
            while (k < face_size) : (k += 1) {
                if (map[@intCast(row)][@intCast(f0.net_x * face_size + k)] == '.') {
                    lx = k;
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
            step_loop: for (0..steps) |_| {
                const f = faces.items[fi];
                const n_f = normalOf(f);
                const center = add3(add3(vec(f.origin, 2), vec(f.u, 2 * lx + 1)), vec(f.v, 2 * ly + 1)); // doubled coords: cell centers at odd lattice
                const h = dirVecOnFace(f, dir);
                const next_center = add(center, vec(h, 2)); // full cell = 2 units in the center lattice

                // try a plain advance on the same face first (origins are in
                // unit lattice — double them for the center lattice)
                const rel = sub(next_center, vec(f.origin, 2));
                const ru = dot(rel, f.u);
                const rv = dot(rel, f.v);
                if (ru >= 0 and ru < 2 * face_size and rv >= 0 and rv < 2 * face_size and dot(rel, n_f) == 0) {
                    if (map[@intCast(f.net_y * face_size + @divTrunc(rv, 2))][@intCast(f.net_x * face_size + @divTrunc(ru, 2))] == '#') break :step_loop;
                    lx = @divTrunc(ru, 2);
                    ly = @divTrunc(rv, 2);
                    continue;
                }

                // crossing an edge: axis through the edge midpoint, along the edge
                const ap = add(center, h); // edge midpoint = one unit (half cell) along h
                const e = cross(n_f, h);

                var done = false;
                for ([2]i32{ 1, -1 }) |sign| {
                    const rot_next = rodrigues(next_center, ap, e, sign);
                    const rot_h = rodrigues(h, .{ 0, 0, 0 }, e, sign);
                    // find the face containing rot_next
                    for (faces.items, 0..) |*g, gi| {
                        const rel2 = sub(rot_next, vec(g.origin, 2));
                        if (dot(rel2, normalOf(g.*)) != 0) continue;
                        const gu = dot(rel2, g.u);
                        const gv = dot(rel2, g.v);
                        if (gu < 0 or gu >= 2 * face_size or gv < 0 or gv >= 2 * face_size) continue;
                        if (@rem(gu, 2) != 1 or @rem(gv, 2) != 1) continue; // must be a cell center
                        const nlx2 = @divTrunc(gu, 2);
                        const nly2 = @divTrunc(gv, 2);
                        const mx = g.net_x * face_size + nlx2;
                        const my = g.net_y * face_size + nly2;
                        if (map[@intCast(my)][@intCast(mx)] == '#') {
                            done = true; // blocked: stop moving, keep state
                            break;
                        }
                        // new local dir from rot_h on g
                        const hu = dot(rot_h, g.u);
                        const hv = dot(rot_h, g.v);
                        var ndir: u8 = 0;
                        if (hu > 0) {
                            ndir = 0;
                        } else if (hu < 0) {
                            ndir = 2;
                        } else if (hv > 0) {
                            ndir = 1;
                        } else {
                            ndir = 3;
                        }
                        fi = gi;
                        lx = nlx2;
                        ly = nly2;
                        dir = ndir;
                        done = true;
                        break;
                    }
                    if (done) break;
                }
                if (!done) {
                    print("fold error at face {d} {d},{d} dir {d}\n", .{ fi, lx, ly, dir });
                    return error.BadFold;
                }
            }
        }
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

fn add3(a: V3, b: V3) V3 {
    return .{ a[0] + b[0], a[1] + b[1], a[2] + b[2] };
}

fn div2(v: V3) V3 {
    return .{ @divTrunc(v[0], 2), @divTrunc(v[1], 2), @divTrunc(v[2], 2) };
}

fn cross(a: V3, b: V3) V3 {
    return .{
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    };
}

/// Rotate p about the axis through ap with unit direction e by +-90 degrees.
fn rodrigues(p: V3, ap: V3, e: V3, sign: i32) V3 {
    // 90-degree Rodrigues: r = ap + cos*(p-ap) + sin*(e x (p-ap)) + (1-cos)(e.(p-ap))e
    // with cos=0, sin=±1: r = ap ± e x d + (d.e)e
    const d = sub(p, ap);
    const exd = cross(e, d);
    const dote = vec(e, dot(d, e));
    return .{
        ap[0] + @as(i32, sign) * exd[0] + dote[0],
        ap[1] + @as(i32, sign) * exd[1] + dote[1],
        ap[2] + @as(i32, sign) * exd[2] + dote[2],
    };
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
const splitSca = std.mem.splitScalar;
const trim = std.mem.trim;
const trimEnd = std.mem.trimEnd;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
