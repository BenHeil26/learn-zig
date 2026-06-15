const std = @import("std");
const Io = std.Io;

const image_filter = @import("image_filter");

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    const help_txt =
        \\ usage: image_filter <path> <out_path>
    ;

    var path: [*c]const u8 = undefined;
    var out_path: [*c]const u8 = undefined;

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    if (args.len != 3) {
        std.log.err(help_txt, .{});
    } else {
        path = @ptrCast(args[1]);
        out_path = @ptrCast(args[2]);
        try image_filter.process_image(path, out_path, arena);
    }

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try stdout_writer.flush(); // Don't forget to flush!
}
