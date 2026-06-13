const std = @import("std");
const Io = std.Io;

const Server = @import("server.zig").Server;
const Request = @import("request.zig");
const Response = @import("response.zig");

pub fn start_server(io: Io) !void {
    const server = try Server.init(io);

    var listening = try server.listen();

    while (true) {
        const connection = try listening.accept(io);
        defer connection.close(io);
        var request_buffer: [1000]u8 = undefined;
        @memset(request_buffer[0..], 0);

        try Request.read_request(io, connection, request_buffer[0..]);
        const request: Request.Request = Request.parse_request(request_buffer[0..]);

        if (std.mem.eql(u8, request.uri, "/")) {
            try Response.send_200(connection, io);
        } else {
            try Response.send_404(connection, io);
        }

        std.debug.print("{any}\n", .{request});
    }
}
