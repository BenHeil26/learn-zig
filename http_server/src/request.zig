const std = @import("std");
const Stream = std.Io.net.Stream;
const Method = @import("method.zig").Method;

pub const Request = struct {
    method: Method,
    version: []const u8,
    uri: []const u8,

    pub fn init(method: Method, version: []const u8, uri: []const u8) Request {
        return Request{ .method = method, .version = version, .uri = uri };
    }
};

pub fn parse_request(text: []const u8) Request {
    const index = std.mem.findScalar(u8, text, '\n') orelse text.len;
    var iter = std.mem.splitScalar(u8, text[0..index], ' ');
    const method = try Method.init(iter.next().?);
    const uri = iter.next().?;
    const version = iter.next().?;
    return Request.init(method, version, uri);
}

pub fn read_request(io: std.Io, conn: Stream, buffer: []u8) !void {
    var recv_buffer: [1024]u8 = undefined;
    var reader = conn.reader(io, &recv_buffer);
    const reader_interface = &reader.interface;

    var start_index: usize = 0;
    for (0..5) |_| {
        const len = try read_next_line(reader_interface, buffer, start_index);
        start_index += len;
    }
}

fn read_next_line(reader: *std.Io.Reader, buffer: []u8, start_index: usize) !usize {
    const next_line = try reader.takeDelimiterInclusive('\n');
    @memcpy(buffer[start_index..(start_index + next_line.len)], next_line[0..]);
    return next_line.len;
}
