const std = @import("std");
const http = @import("apple_pie");

const Context = struct { repo_root: []const u8 };

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
    const repo_root = args[0];

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const listen_addr = try std.net.Address.parseIp("127.0.0.1", 8080);
    try http.FileServer.init(gpa.allocator(), .{
        .dir_path = repo_root,
        .base_path = null,
    });
    const my_context = Context{
        .repo_root = repo_root,
    };
    std.log.info("webserver started at '{}'", .{listen_addr});
    try http.listenAndServe(
        gpa.allocator(),
        listen_addr,
        my_context,
        index,
    );
}

fn index(ctx: Context, response: *http.Response, request: http.Request) !void {
    const path = request.context.uri.path;

    if (std.mem.eql(u8, path, "/zig-out/lib/main.wasm")) {
        //std.log.debug("running zig build...", .{});
        const response_stream = response.writer();
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const result = std.ChildProcess.exec(.{
            .allocator = arena.allocator(),
            .argv = &[_][]const u8 {
                "zig", "build", "wasm",
            },
            .cwd = ctx.repo_root,
        }) catch |err| {
            try response_stream.print("exec 'zig build wasm' failed with error '{s}'", .{@errorName(err)});
            return;
        };
        const success = switch (result.term) {
            .Exited => |code| code == 0,
            else => false,
        };
        if (!success) {
            const sep: []const u8 = if (result.stdout.len > 0 and !std.mem.endsWith(u8, result.stdout, "\n")) "\n" else "";
            try response_stream.print(
                \\zig build wasm failed with:
                \\-------------------------------------------------------------------------------
                \\{s}{s}{s}
                \\--------------------------------------------------------------------------------
                \\
                , .{result.stdout, sep, result.stderr});
            return;
        }
    }

    try http.FileServer.serve({}, response, request);
}
