const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const stdout = std.io.getStdOut().writer();

const data = @embedFile("data/day14.txt");

pub fn main() !void {
    try stdout.print("Part 1: {}\n", .{doPart(comptime data, comptime false)});
    try stdout.print("Part 2: {}\n", .{doPart(comptime data, comptime true)});
}

fn doPart(comptime input: []const u8, comptime has_floor: bool) usize {
    var cave = comptime blk: {
        @setEvalBranchQuota(1_000_000);
        const edge_count = countEdges(input);
        const edges = parseEdges(edge_count, input);
        const shape = getCaveShape(edge_count, edges, has_floor);
        break :blk Cave(shape).create(edge_count, edges);
    };

    if (has_floor) {
        return cave.flood();
    } else {
        return cave.simulate();
    }
}

fn countEdges(input: []const u8) usize {
    return util.count(u8, input, '>');
}

fn parseEdges(comptime edge_count: usize, input: []const u8) [edge_count][2]Pos {
    var edges: [edge_count][2]Pos = undefined;
    var edge_idx: usize = 0;

    var i: usize = 0;
    var last_pos: ?Pos = null;

    while (i < input.len) {
        var start: usize = i;
        while (input[i] != ',') {
            i += 1;
        }
        const x = parseInt(usize, input[start..i], 10) catch unreachable;

        i += 1;
        start = i;
        while (input[i] != ' ' and input[i] != '\n') {
            i += 1;
        }
        const y = parseInt(usize, input[start..i], 10) catch unreachable;

        const pos = Pos{ .x = x, .y = y };

        if (last_pos) |lp| {
            edges[edge_idx][0] = lp;
            edges[edge_idx][1] = pos;
            edge_idx += 1;
        }

        if (input[i] == '\n') {
            last_pos = null;
            i += 1; // skip "\n"
        } else {
            last_pos = pos;
            i += 4; // skip " -> "
        }
    }

    assert(edge_idx == edge_count);

    return edges;
}

fn getCaveShape(comptime edge_count: usize, edges: [edge_count][2]Pos, has_floor: bool) Shape {
    var shape = Shape{
        .min_x = maxInt(usize),
        .max_x = 0,
        .max_y = 0,
        .has_floor = has_floor,
    };

    for (edges) |edge| {
        shape.max_x = max3(edge[0].x, edge[1].x, shape.max_x);
        shape.min_x = min3(edge[0].x, edge[1].x, shape.min_x);
        shape.max_y = max3(edge[0].y, edge[1].y, shape.max_y);
    }

    return shape;
}

const Tile = enum(u8) {
    air,
    rock,
    sand,
    source,

    fn isSolid(self: Tile) bool {
        return self == .rock or self == .sand;
    }
};

const Pos = struct {
    x: usize,
    y: usize,

    fn eq(self: Pos, other: Pos) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Shape = struct {
    min_x: usize,
    max_x: usize,
    max_y: usize,
    has_floor: bool,
};

fn Cave(comptime shape: Shape) type {
    const min_x = if (shape.has_floor) 0 else shape.min_x;
    const max_x = if (shape.has_floor) 1000 else shape.max_x;
    const width = max_x - min_x + 1;
    const height = shape.max_y + 2;
    const size = width * height;

    const source_pos = Pos{ .x = 500, .y = 0 };

    return struct {
        const Self = @This();

        tiles: [size]Tile,

        fn create(comptime edge_count: usize, edges: [edge_count][2]Pos) Self {
            var cave = Self{ .tiles = [_]Tile{.air} ** size };
            cave.set(source_pos, .source);

            for (edges) |edge| {
                const x_step = sign(@bitCast(isize, edge[1].x) - @bitCast(isize, edge[0].x));
                const y_step = sign(@bitCast(isize, edge[1].y) - @bitCast(isize, edge[0].y));

                var pos = edge[0];
                while (!pos.eq(edge[1])) {
                    cave.set(pos, .rock);
                    pos.x = @bitCast(usize, @bitCast(isize, pos.x) + x_step);
                    pos.y = @bitCast(usize, @bitCast(isize, pos.y) + y_step);
                }
                // edges are inclusive of the ends
                cave.set(edge[1], .rock);
            }

            return cave;
        }

        fn set(self: *Self, pos: Pos, val: Tile) void {
            self.tiles[Self.indexOfPos(pos)] = val;
        }

        fn get(self: Self, pos: Pos) Tile {
            return self.tiles[Self.indexOfPos(pos)];
        }

        fn flood(self: *Self) usize {
            // max queue size derived from simplification of the arithmetic series 2*n_i - 1
            var queue = [_]usize{0} ** (height * height);
            var q_head: usize = 0;
            var q_tail: usize = 1;
            queue[0] = Self.indexOfPos(source_pos);

            self.set(source_pos, .sand);

            const bottom_x = height * width;
            var seen: usize = 1;

            while (q_head < q_tail) {
                const tile = queue[q_head];
                q_head += 1;

                const dl = tile + width - 1;

                if (dl >= bottom_x) {
                    continue;
                }

                if (!self.tiles[dl].isSolid()) {
                    self.tiles[dl] = .sand;
                    queue[q_tail] = dl;
                    q_tail += 1;
                    seen += 1;
                }

                const dd = dl + 1;

                if (!self.tiles[dd].isSolid()) {
                    self.tiles[dd] = .sand;
                    queue[q_tail] = dd;
                    q_tail += 1;
                    seen += 1;
                }
                const dr = dd + 1;

                if (!self.tiles[dr].isSolid()) {
                    self.tiles[dr] = .sand;
                    queue[q_tail] = dr;
                    q_tail += 1;
                    seen += 1;
                }
            }

            return seen;
        }

        fn simulate(self: *Self) usize {
            var grains: usize = 0;

            while (self.produce()) |final_pos| {
                self.set(final_pos, .sand);
                grains += 1;
            }

            return grains;
        }

        fn produce(self: Self) ?Pos {
            var pos = source_pos;
            var next_pos = self.next(pos) orelse return null;

            while (!next_pos.eq(pos)) {
                pos = next_pos;
                next_pos = self.next(next_pos) orelse return null;
            }

            return pos;
        }

        fn next(self: Self, pos: Pos) ?Pos {
            var next_pos = Pos{ .x = pos.x, .y = pos.y + 1 };
            if (next_pos.y == height) {
                // fell out the bottom
                return null;
            }

            if (!self.isSolid(next_pos)) {
                return next_pos;
            }

            // directly below is solid, so try below left

            if (next_pos.x == min_x) {
                // fell out the left
                return null;
            }

            next_pos.x -= 1;

            if (!self.isSolid(next_pos)) {
                return next_pos;
            }

            // below left is solid, so try below right

            next_pos.x += 2;

            if (next_pos.x > max_x) {
                // fell out the right
                return null;
            }

            return if (self.isSolid(next_pos)) pos else next_pos;
        }

        fn isSolid(self: Self, pos: Pos) bool {
            if (shape.has_floor) {
                if (pos.y == height - 1) {
                    return true;
                }
            }
            return self.get(pos).isSolid();
        }

        fn indexOfPos(pos: Pos) usize {
            return pos.y * width + (pos.x - min_x);
        }

        fn debugPrint(self: Self) void {
            for (self.tiles) |tile, i| {
                const c: u8 = switch (tile) {
                    .air => '.',
                    .rock => '#',
                    .sand => 'o',
                    .source => '+',
                };
                print("{c}", .{c});

                if (i % width == width - 1) {
                    print("\n", .{});
                }
            }
        }
    };
}

const test_input: []const u8 =
    \\498,4 -> 498,6 -> 496,6
    \\503,4 -> 502,4 -> 502,9 -> 494,9
    \\
;

test "parse" {
    const test_cave = comptime blk: {
        const edge_count = countEdges(test_input);
        const edges = parseEdges(edge_count, test_input);
        const shape = getCaveShape(edge_count, edges, false);
        break :blk Cave(shape).create(edge_count, edges);
    };
    print("\n", .{});
    test_cave.debugPrint();
}

test "day 14 part 1" {
    try t.expectEqual(@as(usize, 24), doPart(comptime test_input, comptime false));
}

test "day 14 part 2" {
    try t.expectEqual(@as(usize, 93), doPart(comptime test_input, comptime true));
}

// Useful stdlib functions
const tokenize = std.mem.tokenize;
const split = std.mem.split;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const min = std.math.min;
const min3 = std.math.min3;
const max = std.math.max;
const max3 = std.math.max3;
const sign = std.math.sign;
const maxInt = std.math.maxInt;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;

const t = std.testing;
const test_alloc = t.allocator;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
