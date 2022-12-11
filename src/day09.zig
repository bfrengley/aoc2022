const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;
const abs = util.abs;

const stdout = std.io.getStdOut().writer();

const data = @embedFile("data/day09.txt");

pub fn main() !void {
    try stdout.print("Part 1: {}\n", .{try doPart(1000, 1000, 2, data)});
    try stdout.print("Part 2: {}\n", .{try doPart(1000, 1000, 10, data)});
}

fn doPart(comptime width: usize, comptime height: usize, comptime rope_length: usize, input: []const u8) !usize {
    var grid = Grid(width, height, rope_length).init();
    var moves = util.lines(input);

    while (moves.next()) |move| {
        try grid.step(move);
    }

    return grid.countVisited();
}

fn Grid(comptime width: usize, comptime height: usize, comptime rope_length: usize) type {
    const flat_size = width * height;
    const mid_x = width / 2;
    const mid_y = height / 2;

    return struct {
        const Self = @This();

        const Pos = struct {
            x: usize,
            y: usize,

            fn flatten(self: Pos) usize {
                return self.y * height + self.x;
            }
        };

        visited: [flat_size]bool = [_]bool{false} ** flat_size,
        rope_parts: [rope_length]Pos = [_]Pos{Pos{ .x = mid_x, .y = mid_y }} ** rope_length,

        fn init() Self {
            var grid = Self{};
            grid.markVisited();
            return grid;
        }

        fn step(self: *Self, move: []const u8) !void {
            var parts = tokenize(u8, move, " ");
            const dir = parts.next().?;
            const dist = try parseInt(usize, parts.next().?, 10);

            for (util.range(dist)) |_| {
                self.moveHead(dir[0]);
                self.moveTail();
            }
        }

        fn moveHead(self: *Self, dir: u8) void {
            switch (dir) {
                'U' => self.rope_parts[0].y += 1,
                'D' => self.rope_parts[0].y -= 1,
                'L' => self.rope_parts[0].x -= 1,
                'R' => self.rope_parts[0].x += 1,
                else => unreachable,
            }
        }

        fn moveTail(self: *Self) void {
            for (self.rope_parts[1..rope_length]) |*follower, i| {
                const leader = self.rope_parts[i];

                const x_dist = @bitCast(isize, leader.x) - @bitCast(isize, follower.x);
                const y_dist = @bitCast(isize, leader.y) - @bitCast(isize, follower.y);

                if (abs(x_dist) <= 1 and abs(y_dist) <= 1) {
                    return;
                }

                follower.x = @bitCast(usize, @bitCast(isize, follower.x) + sign(x_dist));
                follower.y = @bitCast(usize, @bitCast(isize, follower.y) + sign(y_dist));
            }
            self.markVisited();
        }

        fn markVisited(self: *Self) void {
            self.visited[self.rope_parts[rope_length - 1].flatten()] = true;
        }

        fn countVisited(self: Self) usize {
            var count: usize = 0;
            for (self.visited) |v| {
                if (v) {
                    count += 1;
                }
            }
            return count;
        }
    };
}

const test_input: []const u8 =
    \\R 4
    \\U 4
    \\L 3
    \\D 1
    \\R 4
    \\D 1
    \\L 5
    \\R 2
    \\
;

const test_input_part2: []const u8 =
    \\R 5
    \\U 8
    \\L 8
    \\D 3
    \\R 17
    \\D 10
    \\L 25
    \\U 20
    \\
;

test "day 9 part 1" {
    try t.expectEqual(@as(usize, 13), try doPart(20, 20, 2, test_input));
}

test "day 9 part 2" {
    try t.expectEqual(@as(usize, 1), try doPart(20, 20, 10, test_input));
    try t.expectEqual(@as(usize, 36), try doPart(100, 100, 10, test_input_part2));
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
