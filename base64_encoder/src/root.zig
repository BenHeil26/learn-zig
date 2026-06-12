const std = @import("std");
const testing = std.testing;

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

    pub fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }
};

pub fn _calc_encode_length(input: []const u8) !usize {
    if (input.len < 3) {
        return 4;
    }

    const n_groups: usize = try std.math.divCeil(usize, input.len, 3);

    return n_groups * 4;
}

pub fn _calc_decode_length(input: []const u8) !usize {
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
