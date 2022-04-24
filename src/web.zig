const std = @import("std");

pub fn consoleLog(comptime fmt: []const u8, args: anytype) void {
    var buf: [1000]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, fmt, args) catch unreachable;
    jsConsoleLog(@intCast(c_int, @ptrToInt(str.ptr)), @intCast(c_int, str.len));
}

// pub fn consoleLog(string: []const u8) void {
//     const ptr = @intCast(c_int, @ptrToInt(string.ptr));
//     const len = @intCast(c_int, string.len);
//     jsConsoleLog(ptr, len);
// }

pub fn isKeyDown(key_code: c_uint) bool {
    return jsIsKeyDown(key_code);
}

extern fn jsConsoleLog(ptr: c_int, len: c_int) void;
extern fn jsIsKeyDown(key_code: c_uint) bool;