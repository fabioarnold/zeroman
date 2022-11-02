const std = @import("std");
const http = @import("apple_pie");

const Context = struct { };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const all_args = try std.process.argsAlloc(arena.allocator());
    if (all_args.len <= 1) {
        try std.io.getStdErr().writer().writeAll("Usage: webserver ROOT_PATH\n");
        std.os.exit(0xff);
    }
    const args = all_args[1..];
    if (args.len != 1) {
        std.log.err("expected 1 cmdline argument but got {}", .{args.len});
        std.os.exit(0xff);
    }
    const dir_path = args[0];
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const listen_addr = try std.net.Address.parseIp("127.0.0.1", 8080);
    try http.FileServer.init(gpa.allocator(), .{
        .dir_path = dir_path,
        .base_path = null,
    });
    const my_context = Context{ };
    std.log.info("webserver started at '{}'", .{listen_addr});
    try http.listenAndServe(
        gpa.allocator(),
        listen_addr,
        my_context,
        index,
    );
}

fn index(ctx: Context, response: *http.Response, request: http.Request) !void {
    _ = ctx;
    try http.FileServer.serve({}, response, request);
}
