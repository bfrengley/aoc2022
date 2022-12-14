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
    return std.mem.split(u8, trim(u8, input, "\n"), "\n");
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

        pub fn next(self: *Self) ?[]const T {
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

pub fn count(comptime T: type, haystack: []const T, needle: T) usize {
    var seen: usize = 0;
    for (haystack) |v| {
        if (v == needle) {
            seen += 1;
        }
    }
    return seen;
}

pub fn split(comptime T: type, comptime max_parts: usize, raw: []const T, token: T) [max_parts][]const T {
    var parts: [max_parts][]const T = undefined;
    var part_idx: usize = 0;
    var last_idx: usize = 0;
    var idx: usize = 0;

    while (idx < raw.len and part_idx < max_parts) {
        if (raw[idx] == token) {
            parts[part_idx] = raw[last_idx..idx];
            part_idx += 1;
            last_idx = idx + 1;
        }
        idx += 1;
    }

    return parts;
}

pub fn skip(comptime T: type, iter: *T, n: usize) void {
    var i: usize = 0;
    while (i < n) {
        _ = iter.next() orelse return;
        i += 1;
    }
}

/// bound is like clamp, but it returns an error if n is outside the given range and returns n unmodified
/// otherwise.
pub fn bound(comptime T: type, n: T, lower: T, upper: T) error{Overflow}!T {
    if (n < lower or n > upper) {
        return error.Overflow;
    }
    return n;
}

// Useful stdlib functions
const tokenize = std.mem.tokenize;
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
