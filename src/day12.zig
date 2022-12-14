const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const HashMap = std.AutoHashMap;

const util = @import("util.zig");
const gpa = util.gpa;
const bound = util.bound;

const stdout = std.io.getStdOut().writer();

const data = @embedFile("data/day12.txt");

pub fn main() !void {
    const main_map = Map(159, 41).parse(data);
    try stdout.print("Part 1: {}\n", .{try main_map.search(gpa, comptime isValidStart1)});
    try stdout.print("Part 2: {}\n", .{try main_map.search(gpa, comptime isValidStart2)});
}

fn isValidStart1(c: u8) bool {
    return c == 'S';
}

fn isValidStart2(c: u8) bool {
    return c == 'a' or c == 'S';
}

const Direction = enum(usize) {
    n,
    e,
    s,
    w,
};

fn Map(comptime width: usize, comptime height: usize) type {
    const size = width * height;
    const max_x = width - 1;
    const max_y = height - 1;

    return struct {
        const Self = @This();

        const Pos = struct {
            x: usize,
            y: usize,

            fn flatten(self: Pos) usize {
                return self.y * width + self.x;
            }

            fn neighbour(self: Pos, dir: Direction) ?Pos {
                return switch (dir) {
                    .n => Pos{
                        .x = self.x,
                        .y = sub(usize, self.y, 1) catch return null,
                    },
                    .e => Pos{
                        .x = (bound(usize, self.x + 1, 0, max_x) catch return null),
                        .y = self.y,
                    },
                    .s => Pos{
                        .x = self.x,
                        .y = (bound(usize, self.y + 1, 0, max_y) catch return null),
                    },
                    .w => Pos{
                        .x = (sub(usize, self.x, 1) catch return null),
                        .y = self.y,
                    },
                };
            }
        };

        map: [size][4]?usize,
        orig: [size]u8,
        start: usize,
        end: usize,

        fn parse(input: []const u8) Self {
            const lines = util.split(u8, height, input, '\n');

            var new_map = Self{
                .map = [_][4]?usize{([_]?usize{null} ** 4)} ** size,
                .orig = undefined,
                .start = undefined,
                .end = undefined,
            };

            for (lines) |line, y| {
                for (line) |node, x| {
                    const pos = Pos{ .x = x, .y = y };
                    const idx = pos.flatten();
                    new_map.orig[idx] = node;

                    const e = elevation(node);
                    if (node == 'S') {
                        new_map.start = idx;
                    } else if (node == 'E') {
                        new_map.end = idx;
                    }

                    for (util.range(4)) |_, i| {
                        const dir = @intToEnum(Direction, i);
                        const maybe_nb = pos.neighbour(dir);
                        if (maybe_nb) |nb| {
                            const nb_e = elevation(lines[nb.y][nb.x]);
                            // there is a path from a -> b if it is possible to ascend from b to a
                            // or descend from a to b, not the other way
                            // this allows us to start from the end in the graph search and stop at any valid
                            // starting point
                            new_map.map[idx][i] = if ((e >= nb_e and e - nb_e <= 1) or e < nb_e)
                                nb.flatten()
                            else
                                null;
                        } else {
                            new_map.map[idx][i] = null;
                        }
                    }
                }
            }

            return new_map;
        }

        const SearchQueue = std.TailQueue(usize);

        fn search(self: *const Self, alloc: Allocator, comptime isValidStart: fn (u8) bool) !u32 {
            var arena = std.heap.ArenaAllocator.init(alloc);
            defer arena.deinit();
            const a = arena.allocator();

            // BFS

            var queue = SearchQueue{};
            var parents = HashMap(usize, usize).init(a);

            var root = try a.create(SearchQueue.Node);
            root.data = self.end;
            queue.append(root);
            try parents.put(self.end, self.end);

            var found_start: ?usize = null;

            while (queue.len != 0) {
                const node = queue.popFirst().?;
                if (isValidStart(self.orig[node.data])) {
                    found_start = node.data;
                    break;
                }

                for (self.map[node.data]) |n| {
                    if (n) |neighbour| {
                        if (!parents.contains(neighbour)) {
                            try parents.put(neighbour, node.data);
                            var new_node = try a.create(SearchQueue.Node);
                            new_node.data = neighbour;
                            queue.append(new_node);
                        }
                    }
                }

                a.destroy(node);
            }

            assert(found_start != null);

            // re-walk the path
            var path_length: u32 = 0;
            var node = found_start.?;
            while (node != self.end) {
                node = parents.get(node).?;
                path_length += 1;
            }

            return path_length;
        }
    };
}

fn elevation(node: u8) u8 {
    return switch (node) {
        'S' => 0,
        'E' => 'z' - 'a',
        'a'...'z' => node - 'a',
        else => unreachable,
    };
}

const test_input: []const u8 =
    \\Sabqponm
    \\abcryxxl
    \\accszExk
    \\acctuvwj
    \\abdefghi
    \\
;

// const test_map = blk: {
//     @setEvalBranchQuota(10_000);
//     break :blk Map(8, 5).parse(test_input);
// };

test "parse" {
    const test_map = Map(8, 5).parse(test_input);

    // start neighbours
    {
        const neighbours = [_]?usize{
            null,
            1,
            8,
            null,
        };
        try t.expectEqualSlices(?usize, neighbours[0..4], test_map.map[0][0..4]);
    }

    // end neighbours
    {
        const neighbours = [_]?usize{
            null,
            null,
            null,
            20,
        };
        try t.expectEqualSlices(?usize, neighbours[0..4], test_map.map[21][0..4]);
    }
}

test "day 12 part 1" {
    const test_map = Map(8, 5).parse(test_input);
    try t.expectEqual(@as(u32, 31), try test_map.search(std.testing.allocator, comptime isValidStart1));
}

test "day 12 part 2" {
    const test_map = Map(8, 5).parse(test_input);
    try t.expectEqual(@as(u32, 29), try test_map.search(std.testing.allocator, comptime isValidStart2));
}

const sub = std.math.sub;

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
