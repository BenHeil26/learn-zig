const std = @import("std");
const Io = std.Io;

const base64_encoder = @import("base64_encoder");

pub fn main(init: std.process.Init) !void {

    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);

    const help_text =
        \\ usage: base64_encoder <function> <input>
        \\ function is one of the following:
        \\  encode - takes plaintext and encodes it in base64 
        \\  decode - takes base64 and decodes it as plaintext
    ;

    if (args.len < 3) {
        std.log.err(help_text, .{});
    }
    for (args) |arg| {
        std.log.debug("arg: {s}", .{arg});
    }

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;
    const encoder = base64_encoder.Base64.init();

    if (std.mem.eql(u8, args[1], "encode")) {
        _ = try stdout_writer.write(try encoder.encode(args[2], arena));
    } else if (std.mem.eql(u8, args[1], "decode")) {
        _ = try stdout_writer.write(try encoder.decode(args[2], arena));
    } else {
        std.log.err(help_text, .{});
    }

    try stdout_writer.flush(); // Don't forget to flush!
}
