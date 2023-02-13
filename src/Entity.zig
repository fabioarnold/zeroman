const Box = @import("Box.zig");

const Room = @This();

pub const Class = enum {
    player,
    spike,
};

class: Class,
box: Box,