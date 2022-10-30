const std = @import("std");

var buf: [1000]u8 = undefined; // FIXME
var sbuf: [1000]u8 = undefined; // FIXME

pub fn consoleLog(comptime fmt: []const u8, args: anytype) void {
    const str = std.fmt.bufPrint(&buf, fmt, args) catch unreachable;
    jsConsoleLog(@ptrToInt(str.ptr), str.len);
}

pub const LocalStorage = struct {
    pub fn setString(key: []const u8, value: []const u8) void {
        jsStorageSetString(@ptrToInt(key.ptr), key.len, @ptrToInt(value.ptr), value.len);
    }

    pub fn getString(key: []const u8) []const u8 {
        const len = jsStorageGetString(@ptrToInt(key.ptr), key.len, @ptrToInt(&sbuf), sbuf.len);
        return sbuf[0..len];
    }
};

extern fn jsConsoleLog(ptr: usize, len: usize) void;
extern fn jsStorageSetString(key_ptr: usize, key_len: usize, value_ptr: usize, value_len: usize) void;
extern fn jsStorageGetString(key_ptr: usize, key_len: usize, value_ptr: usize, value_len: usize) usize;
pub extern fn isKeyDown(key_code: c_uint) bool;
pub extern fn isButtonDown(button_index: c_uint) bool;