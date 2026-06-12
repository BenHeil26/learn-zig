const std = @import("std");
const testing = std.testing;

const EncoderError = error{ EmptyInput, OutOfRange, MalformedBase64 };
const Base64 = struct {
    _table: *const [64]u8 = undefined,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const num_sym = "0123456789+/";
        return Base64{
            ._table = upper ++ lower ++ num_sym,
        };
    }

    fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }

    fn _char_index(self: Base64, char: u8) u8 {
        if (char == '=') return 64;

        var out_idx: u8 = 0;

        for (0..64) |i| {
            if (self._char_at(i) == char) {
                break;
            }
            out_idx += 1;
        }

        return out_idx;
    }

    pub fn encode(self: Base64, input: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        if (input.len == 0) {
            return EncoderError.EmptyInput;
        }

        const output_size = try _calc_encode_length(input);

        // we dont free because we are returning this!
        var output_buffer = try allocator.alloc(u8, output_size);

        const n_groups = input.len / 3;
        const remainder = input.len % 3;

        var in_win: usize = 0;
        var out_win: usize = 0;

        // handle the perfect groups of three
        for (0..n_groups) |i| {
            in_win = i * 3;
            out_win = i * 4;

            output_buffer[out_win + 0] =
                self._char_at(input[in_win] >> 2);
            output_buffer[out_win + 1] =
                self._char_at(((input[in_win] & 0x3) << 4) + (input[in_win + 1] >> 4));
            output_buffer[out_win + 2] =
                self._char_at(((input[in_win + 1] & 0xf) << 2) + (input[in_win + 2] >> 6));
            output_buffer[out_win + 3] =
                self._char_at(input[in_win + 2] & 0x3f);
        }

        const lin_win = n_groups * 3;
        const lout_win = n_groups * 4;

        // handle the bytes left
        switch (remainder) {
            2 => {
                output_buffer[lout_win + 0] =
                    self._char_at(input[lin_win] >> 2);
                output_buffer[lout_win + 1] =
                    self._char_at(((input[lin_win] & 0x3) << 4) + (input[lin_win + 1] >> 4));
                output_buffer[lout_win + 2] =
                    self._char_at((input[lin_win + 1] & 0xf) << 2);
                output_buffer[lout_win + 3] = '=';
            },
            1 => {
                output_buffer[lout_win + 0] =
                    self._char_at(input[lin_win] >> 2);
                output_buffer[lout_win + 1] =
                    self._char_at((input[lin_win] & 0x3) << 4);
                output_buffer[lout_win + 2] = '=';
                output_buffer[lout_win + 3] = '=';
            },
            0 => {},
            else => unreachable,
        }

        return output_buffer;
    }

    pub fn decode(self: Base64, input: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        if (input.len == 0) {
            return EncoderError.EmptyInput;
        }

        if (input.len % 4 != 0) {
            return EncoderError.MalformedBase64;
        }

        // we need to reverse the operations from encode(), so we
        //  load up a buffer of indexes based on the input characters
        //  alloc to the heap because of size concerns
        var idx_buf = try allocator.alloc(u8, input.len);
        defer allocator.free(idx_buf);

        for (0..input.len) |i| {
            idx_buf[i] = self._char_index(input[i]);
        }

        // our input is always a multiple of 4 bytes by definition
        //  (and checked above) so we don't need to worry about
        //  the remainder
        const num_groups = input.len / 4;
        var output_buffer = try allocator.alloc(u8, try _calc_decode_length(input));

        var in_win: usize = 0;
        var out_win: usize = 0;

        // reverse the encode() operations
        //  again, simpler because the remainder is not a factor,
        //  but we do have to account for any of the null trailer chars '='/64
        //  in the last two positions of idx_buf
        for (0..num_groups) |i| {
            in_win = i * 4;
            out_win = i * 3;

            output_buffer[out_win + 0] =
                (idx_buf[in_win] << 2) + (idx_buf[in_win + 1] >> 4);
            if (idx_buf[in_win + 2] != 64) {
                output_buffer[out_win + 1] =
                    (idx_buf[in_win + 1] << 4) + (idx_buf[in_win + 2] >> 2);
            }
            if (idx_buf[in_win + 3] != 64) {
                output_buffer[out_win + 2] =
                    (idx_buf[in_win + 2] << 6) + (idx_buf[in_win + 3]);
            }
        }

        return output_buffer;
    }
};

fn _calc_encode_length(input: []const u8) !usize {
    if (input.len < 3) {
        return 4;
    }

    const n_groups: usize = try std.math.divCeil(usize, input.len, 3);

    return n_groups * 4;
}

fn _calc_decode_length(input: []const u8) !usize {
    if (input.len < 4) {
        return 3;
    }

    const n_groups: usize = try std.math.divFloor(usize, input.len, 4);
    var multiple_groups = n_groups * 3;

    for (1..input.len + 1) |i| {
        if (input[input.len - i] == '=') {
            multiple_groups -= 1;
        } else break;
    }

    return multiple_groups;
}

test "_char_at 28" {
    const base64 = Base64.init();
    try testing.expect(base64._char_at(28) == 'c');
}

test "_char_index c" {
    const base64 = Base64.init();
    try testing.expect(base64._char_index('c') == 28);
}

test "_calc_encode_length" {
    const test_cases = .{ .{ "hi", 4 }, .{ "longer", 8 } };
    inline for (test_cases) |test_case| {
        const result = try _calc_encode_length(test_case.@"0");
        try testing.expectEqual(test_case.@"1", result);
    }
}

test "_calc_decode_length" {
    const test_cases = .{ .{ "aGk=", 2 }, .{ "aGVsbG8gd29ybGQ=", 11 } };
    inline for (test_cases) |test_case| {
        const result = try _calc_decode_length(test_case.@"0");
        try testing.expectEqual(test_case.@"1", result);
    }
}

test "encode" {
    const base64 = Base64.init();
    const test_cases =
        .{ .{ "hey yo", "aGV5IHlv" }, .{ "Hello world", "SGVsbG8gd29ybGQ=" }, .{ "Heyo world", "SGV5byB3b3JsZA==" } };
    const allocator = std.testing.allocator;
    inline for (test_cases) |test_case| {
        const result = try base64.encode(test_case.@"0", allocator);
        try testing.expectEqualSlices(u8, test_case.@"1", result);
        allocator.free(result);
    }
}

test "decode" {
    const base64 = Base64.init();
    const test_cases =
        .{ .{ "hey yo", "aGV5IHlv" }, .{ "Hello world", "SGVsbG8gd29ybGQ=" }, .{ "Heyo world", "SGV5byB3b3JsZA==" } };
    const allocator = std.testing.allocator;
    inline for (test_cases) |test_case| {
        const result = try base64.decode(test_case.@"1", allocator);
        try testing.expectEqualSlices(u8, test_case.@"0", result);
        allocator.free(result);
    }
}
