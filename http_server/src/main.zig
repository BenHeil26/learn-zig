const std = @import("std");
const Io = std.Io;

const Server = @import("server.zig").Server;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const server = try Server.init(io);
    var listening = try server.listen();
    const connection = try listening.accept(io);
    defer connection.close(io);
}
