const std = @import("std");
const GameData = @import("main.zig").GameData;
const Box = @import("Box.zig");
const Attrib = @import("Tile.zig").Attrib;
const Room = @import("Room.zig");
const Renderer = @import("Renderer.zig");
const Rect = Renderer.Rect;

const Self = @This();

pub const Type = enum {
    gopher,
};

pub var gopher_sprite: Renderer.Texture = undefined;

active: bool = false,
type: Type = undefined,
box: Box = undefined,
state: u8 = 0,
frame: u8 = 0,
counter: i32 = 0,
flip_x: bool = false,

pub fn load() void {
    gopher_sprite.loadFromUrl("img/gopher.png", 72, 24);
}

pub fn activate(self: *Self, @"type": Type, box: Box) void {
    self.active = true;
    self.type = @"type";
    self.box = box;
    switch (@"type") {
        .gopher => {},
    }
    self.state = 0;
    self.frame = 0;
    self.counter = 0;
}

pub fn tick(self: *Self, r: std.rand.Random, game: *GameData, attribs: []const Attrib) void {
    switch (self.type) {
        .gopher => tickGopher(self, r, game, attribs),
    }
}

pub fn draw(self: Self) void {
    switch (self.type) {
        .gopher => drawGopher(self),
    }
}

const GopherState = enum(u8) {
    idle = 0,
    walk = 1,
};

fn tickGopher(self: *Self, r: std.rand.Random, game: *GameData, attribs: []const Attrib) void {
    const room = game.getCurrentRoom();
    const state: *GopherState = @ptrCast(&self.state);
    switch (state.*) {
        .idle => {
            self.frame = 0;
            self.flip_x = self.counter & 16 != 0;
            if (self.counter <= 0) {
                self.counter = r.intRangeLessThan(i32, 100, 500);
                state.* = .walk;
            }
        },
        .walk => {
            self.frame = if (self.counter & 8 != 0) 1 else 2;
            const amount: i32 = if (self.flip_x) -1 else 1;
            const sense_x = self.box.x + @divTrunc(self.box.w + amount * self.box.w, 2);
            if (room.getTileAttribAtPixel(attribs, sense_x, self.box.y + self.box.h) != .solid or room.clipX(attribs, self.box, amount) != amount) {
                self.flip_x = !self.flip_x;
            } else {
                self.box.x += amount;
            }
            if (self.counter <= 0) {
                self.counter = r.intRangeLessThan(i32, 100, 200);
                state.* = .idle;
            }
        },
    }
    self.counter -= 1;

    if (self.box.overlaps(game.player.box)) {
        game.player.hurt(4);
    }
}

fn drawGopher(self: Self) void {
    var src_rect = Rect.init(self.frame * 24, 0, 24, 24);
    const dst_rect = Rect.init(self.box.x - 4, self.box.y, 24, 24);
    if (self.flip_x) {
        src_rect.x += src_rect.w;
        src_rect.w = -src_rect.w;
    }
    Renderer.Sprite.drawFromTo(gopher_sprite, src_rect, dst_rect);
}
