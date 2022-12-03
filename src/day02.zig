const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day02.txt");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Part 1: {}\n", .{try doPart(data, comptime Round.fromChoice)});
    try stdout.print("Part 2: {}\n", .{try doPart(data, comptime Round.fromOutcome)});
}

fn doPart(input: []const u8, comptime parse_line: @TypeOf(Round.fromChoice)) !i32 {
    const rounds = try parse(gpa, input, parse_line);
    defer gpa.free(rounds);

    var score: i32 = 0;
    for (rounds) |round| {
        score += round.score();
    }
    return score;
}

const Outcome = enum(i32) {
    loss = 0,
    draw = 3,
    win = 6,

    fn parse(char: u8) Outcome {
        return switch (char) {
            'X' => .loss,
            'Y' => .draw,
            'Z' => .win,
            else => unreachable,
        };
    }
};

const Choice = enum(i32) {
    rock = 1,
    paper = 2,
    scissors = 3,

    fn parse(char: u8) Choice {
        return switch (char) {
            'A', 'X' => .rock,
            'B', 'Y' => .paper,
            'C', 'Z' => .scissors,
            else => unreachable,
        };
    }

    fn beats(self: Choice) Choice {
        return switch (self) {
            .rock => .scissors,
            inline else => |val| @intToEnum(Choice, @enumToInt(val) - 1),
        };
    }

    fn losesTo(self: Choice) Choice {
        return switch (self) {
            .scissors => .rock,
            inline else => |val| @intToEnum(Choice, @enumToInt(val) + 1),
        };
    }
};

const Round = struct {
    opp: Choice,
    me: Choice,

    fn fromChoice(line: []const u8) Round {
        return Round{
            .opp = Choice.parse(line[0]),
            .me = Choice.parse(line[2]),
        };
    }

    fn fromOutcome(line: []const u8) Round {
        const opp = Choice.parse(line[0]);
        const result = Outcome.parse(line[2]);

        return Round{
            .opp = opp,
            .me = switch (result) {
                .draw => opp,
                .win => opp.losesTo(),
                .loss => opp.beats(),
            },
        };
    }

    fn score(self: Round) i32 {
        return @enumToInt(self.me) + @enumToInt(self.outcome());
    }

    fn outcome(self: Round) Outcome {
        if (self.opp == self.me) {
            return .draw;
        }

        return if (self.me.beats() == self.opp) .win else .loss;
    }
};

fn parse(alloc: Allocator, input: []const u8, comptime parse_line: @TypeOf(Round.fromChoice)) ![]Round {
    var lines = split(u8, trim(u8, input, "\n"), "\n");
    var rounds = List(Round).init(alloc);

    while (lines.next()) |line| {
        try rounds.append(parse_line(line));
    }

    return rounds.toOwnedSlice();
}

const test_input: []const u8 =
    \\A Y
    \\B X
    \\C Z
    \\
;

test "parse - part 1" {
    const rounds = try parse(std.testing.allocator, test_input, comptime Round.fromChoice);
    defer std.testing.allocator.free(rounds);

    const expected = [_]Round{
        Round{ .opp = .rock, .me = .paper },
        Round{ .opp = .paper, .me = .rock },
        Round{ .opp = .scissors, .me = .scissors },
    };
    try std.testing.expectEqualSlices(Round, expected[0..expected.len], rounds);
}

test "parse - part 2" {
    const rounds = try parse(std.testing.allocator, test_input, comptime Round.fromOutcome);
    defer std.testing.allocator.free(rounds);

    const expected = [_]Round{
        Round{ .opp = .rock, .me = .rock },
        Round{ .opp = .paper, .me = .rock },
        Round{ .opp = .scissors, .me = .rock },
    };
    try std.testing.expectEqualSlices(Round, expected[0..expected.len], rounds);
}

test "day 2 part 1" {
    try std.testing.expectEqual(@as(i32, 15), try doPart(test_input, comptime Round.fromChoice));
}

test "day 2 part 2" {
    try std.testing.expectEqual(@as(i32, 12), try doPart(test_input, comptime Round.fromOutcome));
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

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
