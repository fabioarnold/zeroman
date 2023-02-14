const std = @import("std");
const Box = @import("Box.zig");
const Attrib = @import("Tile.zig").Attrib;
const Room = @import("Room.zig");
const Renderer = @import("Renderer.zig");
const Rect2 = Renderer.Rect2;

const Self = @This();

pub const Type = enum {
    gopher,

    pub fn jsonStringify(value: Type, options: std.json.StringifyOptions, out_stream: anytype) !void {
        _ = options;
        try out_stream.writeByte('"');
        try out_stream.writeAll(std.meta.tagName(value));
        try out_stream.writeByte('"');
    }
};

pub var gopher_sprite: Renderer.Texture = undefined;

active: bool = false,
@"type": Type = undefined,
box: Box = undefined,
state: u8 = 0,
frame: u8 = 0,
counter: u32 = 0,
flip_x: bool = false,

pub fn load() void {
    gopher_sprite.loadFromUrl("img/gopher.png", 72, 24);
}

pub fn activate(self: *Self, @"type": Type, box: Box) void {
    self.active = true;
    self.@"type" = @"type";
    self.box = box;
    switch (@"type") {
        .gopher => {},
    }
    self.state = 0;
    self.frame = 0;
    self.counter = 0;
}

pub fn tick(self: *Self, room: Room, attribs: []const Attrib) void {
    switch (self.@"type") {
        .gopher => tickGopher(self, room, attribs),
    }
}

pub fn draw(self: Self) void {
    switch (self.@"type") {
        .gopher => drawGopher(self),
    }
}

const GopherState = enum(u8) {
    idle = 0,
    walk = 1,
};

fn tickGopher(self: *Self, room: Room, attribs: []const Attrib) void {
    var state = @ptrCast(*GopherState, &self.state);
    switch (state.*) {
        .idle => {
            self.frame = 0;
            self.flip_x = self.counter & 16 != 0;
            if (self.counter >= 128) {
                self.counter = 0;
                state.* = .walk;
            }
        },
        .walk => {
            self.frame = if (self.counter & 8 != 0) 1 else 2;
            const amount: i32 = if (self.flip_x) - 1 else 1;
            if (room.clipX(attribs, self.box, amount) != amount) {
                self.flip_x = !self.flip_x;
            } else {
                self.box.x += amount;
            }
            if (self.counter >= 128) {
                self.counter = 0;
                state.* = .idle;
            }
        },
    }
    self.counter += 1;
}

fn drawGopher(self: Self) void {
    var src_rect = Rect2.init(@intToFloat(f32, self.frame * 24), 0, 24, 24);
    var dst_rect = Rect2.init(@intToFloat(f32, self.box.x) - 8, @intToFloat(f32, self.box.y), src_rect.w, src_rect.h);
    if (self.flip_x) {
        src_rect.x += src_rect.w;
        src_rect.w = -src_rect.w;
    }
    Renderer.Sprite.draw(gopher_sprite, src_rect, dst_rect);
}
