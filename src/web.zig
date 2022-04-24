const std = @import("std");

pub fn consoleLog(comptime fmt: []const u8, args: anytype) void {
    var buf: [1000]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, fmt, args) catch unreachable;
    jsConsoleLog(@intCast(c_int, @ptrToInt(str.ptr)), @intCast(c_int, str.len));
}

extern fn jsConsoleLog(ptr: c_int, len: c_int) void;
pub extern fn isKeyDown(key_code: c_uint) bool;
pub extern fn isButtonDown(button_index: c_uint) bool;