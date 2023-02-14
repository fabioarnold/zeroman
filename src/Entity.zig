const Box = @import("Box.zig");

const Room = @This();

pub const Class = enum {
    player,
    gopher,
    spike,
};

class: Class,
box: Box,