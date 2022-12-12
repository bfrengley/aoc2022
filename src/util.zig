const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_impl.allocator();

// Add utility functions here

pub fn lines(input: []const u8) std.mem.SplitIterator(u8) {
    return split(u8, trim(u8, input, "\n"), "\n");
}

// wtf
// https://www.reddit.com/r/Zig/comments/p2clkk/comment/h8kajs7/?context=3
pub fn range(len: usize) []const u0 {
    return @as([*]u0, undefined)[0..len];
}

pub fn abs(x: anytype) @TypeOf(x) {
    return std.math.absInt(x) catch unreachable;
}

pub fn ChunkedIterator(comptime T: type) type {
    return struct {
        const Self = @This();

        slice: []const T,
        index: ?usize,
        chunk_size: usize,

        pub fn next(self: *Self) ?[]const u8 {
            const start = self.index orelse return null;
            const max_chunk_end = start + self.chunk_size;

            const end = if (max_chunk_end < self.slice.len) blk: {
                self.index = max_chunk_end;
                break :blk max_chunk_end;
            } else blk: {
                self.index = null;
                break :blk self.slice.len;
            };

            return self.slice[start..end];
        }

        pub fn reset(self: *Self) void {
            self.index = 0;
        }
    };
}

pub fn chunked(comptime T: type, slice: []const T, chunk_size: usize) ChunkedIterator(T) {
    return ChunkedIterator(T){ .slice = slice, .index = 0, .chunk_size = chunk_size };
}

pub fn WindowIterator(comptime T: type) type {
    return struct {
        const Self = @This();

        slice: []const T,
        index: ?usize,
        window_size: usize,

        pub fn next(self: *Self) ?[]const u8 {
            const start = self.index orelse return null;
            const end = start + self.window_size;

            if (end >= self.slice.len) {
                self.index = null;
                return null;
            }

            self.index = start + 1;
            return self.slice[start..end];
        }

        pub fn reset(self: *Self) void {
            self.index = 0;
        }
    };
}

pub fn windows(comptime T: type, slice: []const T, window_size: usize) WindowIterator(T) {
    return WindowIterator(T){ .slice = slice, .index = 0, .window_size = window_size };
}

pub fn skip(comptime T: type, iter: *T, count: usize) void {
    var i: usize = 0;
    while (i < count) {
        _ = iter.next() orelse return;
        i += 1;
    }
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
