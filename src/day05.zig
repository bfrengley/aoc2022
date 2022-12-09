const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const stdout = std.io.getStdOut().writer();

const data = @embedFile("data/day05.txt");

pub fn main() !void {
    try stdout.print("Part 1: {s}\n", .{try doPart(9, .cm9000, data)});
    try stdout.print("Part 2: {s}\n", .{try doPart(9, .cm9001, data)});
}

fn doPart(comptime N: usize, comptime C: CraneType, input: []const u8) ![]const u8 {
    var parts = split(u8, input, "\n\n");
    var stack = try CrateStacks(N, C).parse(parts.first());
    defer stack.deinit();
    var instr_iter = util.lines(parts.rest());

    while (instr_iter.next()) |instr| {
        var instr_parts = split(u8, instr, " ");
        _ = instr_parts.first();
        const count = try parseInt(usize, instr_parts.next().?, 10);
        _ = instr_parts.next();
        const from = try parseInt(usize, instr_parts.next().?, 10) - 1;
        _ = instr_parts.next();
        const to = try parseInt(usize, instr_parts.next().?, 10) - 1;

        try stack.move(from, to, count);
    }

    var msg = List(u8).init(gpa);
    defer msg.deinit();
    for (stack.stacks) |*s| {
        try msg.append(s.pop());
    }
    return try msg.toOwnedSlice();
}

const CraneType = enum {
    cm9000,
    cm9001,
};

fn CrateStacks(comptime N: usize, comptime C: CraneType) type {
    return struct {
        const Self = @This();

        stacks: [N]List(u8),

        fn parse(input: []const u8) !Self {
            var stacks = Self.init();

            var iter = std.mem.splitBackwards(u8, input, "\n");
            var reading = false;

            while (iter.next()) |line| {
                if (line.len >= 2 and line[1] == '1') {
                    reading = true;
                    continue;
                } else if (!reading) {
                    continue;
                }

                var chunks = util.chunked(u8, line, 4);
                var stack: usize = 0;

                while (chunks.next()) |chunk| {
                    assert(chunk.len >= 2);

                    if (chunk[0] == '[') {
                        try stacks.push(stack, chunk[1]);
                    }
                    stack += 1;
                }
            }

            return stacks;
        }

        fn init() Self {
            var c = Self{ .stacks = undefined };
            for (c.stacks) |*pt| {
                pt.* = List(u8).init(gpa);
            }
            return c;
        }

        fn deinit(self: Self) void {
            for (self.stacks) |*stack| {
                stack.deinit();
            }
        }

        fn push(self: *Self, stack: usize, val: u8) !void {
            assert(stack < N);

            try self.stacks[stack].append(val);
        }

        fn move(self: *Self, from: usize, to: usize, count: usize) !void {
            assert(from < N and to < N);

            if (C == .cm9000) {
                var c = count;
                while (c > 0) {
                    try self.stacks[to].append(self.stacks[from].pop());
                    c -= 1;
                }
            } else {
                const l = self.stacks[from].items.len;
                try self.stacks[to].appendSlice(self.stacks[from].items[l - count .. l]);
                self.stacks[from].items.len = l - count;
            }
        }
    };
}

const test_input: []const u8 =
    \\    [D]
    \\[N] [C]
    \\[Z] [M] [P]
    \\ 1   2   3
    \\
    \\move 1 from 2 to 1
    \\move 3 from 1 to 3
    \\move 2 from 2 to 1
    \\move 1 from 1 to 2
    \\
;

test "parse" {
    const expected = [3][3]?u8{
        [_]?u8{ 'Z', 'N', null },
        [_]?u8{ 'M', 'C', 'D' },
        [_]?u8{ 'P', null, null },
    };

    const stacks = try CrateStacks(3, .cm9000).parse(test_input);
    defer stacks.deinit();

    for (expected) |stack, i| {
        for (stack) |v, j| {
            const expect = v orelse continue;
            try t.expectEqual(expect, stacks.stacks[i].items[j]);
        }
    }
}

test "day 5 part 1" {
    const expected: []const u8 = "CMZ";
    try t.expectEqualSlices(u8, expected, try doPart(3, .cm9000, test_input));
}

test "day 5 part 2" {
    const expected: []const u8 = "MCD";
    try t.expectEqualSlices(u8, expected, try doPart(3, .cm9001, test_input));
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
