const Box = @import("Box.zig");

const Room = @This();

pub const Class = enum {
    spike,
};

class: Class,
box: Box,