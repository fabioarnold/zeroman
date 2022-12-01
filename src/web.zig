const std = @import("std");

const WriteError = error{
    NoSpaceLeft,
};

fn writeLog(_: void, msg: []const u8) WriteError!usize {
    jsLogWrite(msg.ptr, msg.len);
    return msg.len;
}

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = switch (message_level) {
        .err => "error",
        .warn => "warning",
        .info => "info",
        .debug => "debug",
    };
    const prefix = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    const writer = std.io.Writer(void, WriteError, writeLog){.context = {}};
    writer.print(level_txt ++ prefix ++ format ++ "\n", args) catch return;

    jsLogFlush();
}

var sbuf: [1000]u8 = undefined; // FIXME

pub const LocalStorage = struct {
    pub fn setString(key: []const u8, value: []const u8) void {
        jsStorageSetString(@ptrToInt(key.ptr), key.len, @ptrToInt(value.ptr), value.len);
    }

    pub fn getString(key: []const u8) []const u8 {
        const len = jsStorageGetString(@ptrToInt(key.ptr), key.len, @ptrToInt(&sbuf), sbuf.len);
        return sbuf[0..len];
    }
};

extern fn jsLogWrite(ptr: [*]const u8, len: usize) void;
extern fn jsLogFlush() void;
extern fn jsStorageSetString(key_ptr: usize, key_len: usize, value_ptr: usize, value_len: usize) void;
extern fn jsStorageGetString(key_ptr: usize, key_len: usize, value_ptr: usize, value_len: usize) usize;
pub extern fn hasLoadSnapshot() bool;
pub extern fn isKeyDown(key_code: c_uint) bool;
pub extern fn isButtonDown(button_index: c_uint) bool;
