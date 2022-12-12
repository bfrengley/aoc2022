const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const stdout = std.io.getStdOut().writer();

const data = @embedFile("data/day11.txt");

pub fn main() !void {
    try stdout.print("Part 1: {}\n", .{try doPart(8, gpa, data, 20)});
    try stdout.print("Part 1: {}\n", .{try doPart(8, gpa, data, 10_000)});
}

fn doPart(comptime size: usize, alloc: Allocator, input: []const u8, rounds: usize) !u64 {
    var gang: MonkeyGang(size) = undefined;
    try gang.parse(alloc, input);
    gang.reduce_worry = rounds == 20;
    defer gang.arena.deinit();

    for (util.range(rounds)) |_| {
        try gang.runTurn();
    }

    var inspections: [size]u64 = undefined;
    for (gang.monkeys) |*monkey, i| {
        inspections[i] = monkey.inspections;
    }

    sort(u64, inspections[0..size], {}, desc(u64));

    return inspections[0] * inspections[1];
}

const Operator = enum {
    add,
    mul,
};

const Operation = struct {
    operator: Operator,
    operand: ?i64,

    fn run(self: Operation, old: i64) i64 {
        return switch (self.operator) {
            .add => old + (self.operand orelse old),
            .mul => old * (self.operand orelse old),
        };
    }
};

const Monkey = struct {
    items: List(i64),
    operation: Operation,
    test_num: i64,
    true_target: usize,
    false_target: usize,
    inspections: u64 = 0,
};

fn MonkeyGang(comptime size: usize) type {
    return struct {
        const Self = @This();

        arena: ArenaAllocator,
        monkeys: [size]Monkey,
        reduce_worry: bool,
        modulo: i64,

        fn parse(self: *Self, alloc: Allocator, input: []const u8) !void {
            self.arena = ArenaAllocator.init(alloc);
            self.monkeys = undefined;
            self.modulo = 1;
            errdefer self.arena.deinit();

            var lines = util.lines(input);

            while (lines.next()) |line| {
                if (line.len == 0) {
                    continue;
                }

                const n = @as(usize, line[7] - '0');
                assert(n < size);

                var monkey = &self.monkeys[n];
                monkey.items = List(i64).init(self.arena.allocator());
                monkey.inspections = 0;

                const items_line = lines.next().?;
                // skip "  Starting items: "
                var items_iter = tokenize(u8, items_line[18..items_line.len], ", ");
                while (items_iter.next()) |item| {
                    try monkey.items.append(try parseInt(i64, item, 10));
                }

                const op_line = lines.next().?;
                // skip "  Operation: new = old "
                var op_iter = tokenize(u8, op_line[23..op_line.len], " ");
                const op = switch (op_iter.next().?[0]) {
                    '*' => Operator.mul,
                    '+' => Operator.add,
                    else => unreachable,
                };
                const operand = parseInt(i64, op_iter.next().?, 10) catch null;
                monkey.operation = Operation{ .operator = op, .operand = operand };

                const test_line = lines.next().?;
                // skip "  Test: divisible by "
                monkey.test_num = try parseInt(i64, test_line[21..test_line.len], 10);
                self.modulo *= monkey.test_num;

                const true_line = lines.next().?;
                // skip "    If true: throw to monkey "
                monkey.true_target = try parseInt(usize, true_line[29..true_line.len], 10);
                assert(monkey.true_target < size);

                const false_line = lines.next().?;
                // skip "    If false: throw to monkey "
                monkey.false_target = try parseInt(usize, false_line[30..false_line.len], 10);
                assert(monkey.false_target < size);
            }
        }

        fn runTurn(self: *Self) !void {
            for (self.monkeys) |*monkey| {
                try self.runRound(monkey);
            }
        }

        fn runRound(self: *Self, monkey: *Monkey) !void {
            const items = try monkey.items.toOwnedSlice();
            defer self.arena.allocator().free(items);

            for (items) |item| {
                var new_item = monkey.operation.run(item);
                if (self.reduce_worry) {
                    new_item = @divTrunc(new_item, 3);
                }
                new_item = @mod(new_item, self.modulo);

                monkey.inspections += 1;

                const target = if (@mod(new_item, monkey.test_num) == 0) monkey.true_target else monkey.false_target;
                try self.monkeys[target].items.append(new_item);
            }
        }
    };
}

const test_input = @embedFile("data/day11_test.txt");

test "day 11 part 1" {
    try t.expectEqual(@as(u64, 10605), try doPart(4, test_alloc, test_input, 20));
}

test "day 11 part 2" {
    try t.expectEqual(@as(u64, 2713310158), try doPart(4, test_alloc, test_input, 10_000));
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
