const std = @import("std");
const Io = std.Io;

const http_server = @import("http_server");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    try http_server.start_server(io);
}
