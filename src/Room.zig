const std = @import("std");

const Box = @import("Box.zig");
const Tile = @import("Tile.zig");
const Entity = @import("Entity.zig");

const Room = @This();

pub const no_door = 0xFF;

bounds: Box,

width: u8,
height: u8,
data: []const u8,

entities: []const Entity = &.{},

door1_y: u8 = no_door,
door2_y: u8 = no_door,

pub fn clipX(self: Room, attribs: []const Tile.Attrib, mover: Box, amount: i32) i32 {
    if (amount == 0) return 0;
    var clipped = amount;

    // HACK clip against origin in needleman stage
    if (mover.x + clipped < 0) clipped = -mover.x;

    // move mover into room space
    const box = Box{ .x = mover.x - self.bounds.x, .y = mover.y - self.bounds.y, .w = mover.w, .h = mover.h };

    // calc affected area
    const area = if (clipped > 0)
        Box{ .x = box.x + box.w, .y = box.y, .w = clipped, .h = box.h }
    else
        Box{ .x = box.x + clipped, .y = box.y, .w = -clipped, .h = box.h };

    const start_x: u16 = @intCast(std.math.clamp(@divTrunc(area.x, Tile.size), 0, self.width - 1));
    const stop_x: u16 = @intCast(std.math.clamp(@divTrunc(area.x + area.w - 1, Tile.size), 0, self.width - 1));
    const start_y: u16 = @intCast(std.math.clamp(@divTrunc(area.y, Tile.size), 0, self.height - 1));
    const stop_y: u16 = @intCast(std.math.clamp(@divTrunc(area.y + area.h - 1, Tile.size), 0, self.height - 1));

    var y = start_y;
    while (y <= stop_y) : (y += 1) {
        var x = start_x;
        while (x <= stop_x) : (x += 1) {
            const tile_index = self.data[y * self.width + x];
            const attrib = attribs[tile_index];
            if (attrib == .solid) {
                const solid = Box{ .x = x * Tile.size, .y = y * Tile.size, .w = Tile.size, .h = Tile.size };
                clipped = box.castX(clipped, solid);
            }
        }
    }

    return clipped;
}

pub fn clipY(self: Room, attribs: []const Tile.Attrib, mover: Box, amount: i32) i32 {
    if (amount == 0) return 0;
    var clipped = amount;

    // move mover into room space
    const box = Box{ .x = mover.x - self.bounds.x, .y = mover.y - self.bounds.y, .w = mover.w, .h = mover.h };

    // calc affected area
    const area = if (clipped > 0)
        Box{ .x = box.x, .y = box.y + box.h, .w = box.w, .h = clipped }
    else
        Box{ .x = box.x, .y = box.y + clipped, .w = box.w, .h = -clipped };

    const start_x: u16 = @intCast(std.math.clamp(@divTrunc(area.x, Tile.size), 0, self.width - 1));
    const stop_x: u16 = @intCast(std.math.clamp(@divTrunc(area.x + area.w - 1, Tile.size), 0, self.width - 1));
    const start_y: u16 = @intCast(std.math.clamp(@divTrunc(area.y, Tile.size), 0, self.height - 1));
    const stop_y: u16 = @intCast(std.math.clamp(@divTrunc(area.y + area.h - 1, Tile.size), 0, self.height - 1));

    var y = start_y;
    while (y <= stop_y) : (y += 1) {
        var x = start_x;
        while (x <= stop_x) : (x += 1) {
            const tile_index = self.data[y * self.width + x];
            const attrib = attribs[tile_index];
            if (attrib == .solid) {
                const solid = Box{ .x = x * Tile.size, .y = y * Tile.size, .w = Tile.size, .h = Tile.size };
                clipped = box.castY(clipped, solid);
            } else if (attrib == .ladder and clipped > 0 and y > 0) { // top of ladder
                if (self.getTileAttribAtTile(attribs, x, y - 1) == .none) {
                    const solid = Box{ .x = x * Tile.size, .y = y * Tile.size, .w = Tile.size, .h = Tile.size };
                    clipped = box.castY(clipped, solid);
                }
            }
        }
    }

    return clipped;
}

pub fn overlap(self: Room, attribs: []const Tile.Attrib, mover: Box) bool {
    // move mover into room space
    const box = Box{ .x = mover.x - self.bounds.x, .y = mover.y - self.bounds.y, .w = mover.w, .h = mover.h };

    const start_x: u16 = @intCast(std.math.clamp(@divTrunc(box.x, Tile.size), 0, self.width - 1));
    const stop_x: u16 = @intCast(std.math.clamp(@divTrunc(box.x + box.w - 1, Tile.size), 0, self.width - 1));
    const start_y: u16 = @intCast(std.math.clamp(@divTrunc(box.y, Tile.size), 0, self.height - 1));
    const stop_y: u16 = @intCast(std.math.clamp(@divTrunc(box.y + box.h - 1, Tile.size), 0, self.height - 1));

    var y = start_y;
    while (y <= stop_y) : (y += 1) {
        var x = start_x;
        while (x <= stop_x) : (x += 1) {
            const tile_index = self.data[y * self.width + x];
            const attrib = attribs[tile_index];
            if (attrib == .solid) {
                const solid = Box{ .x = x * Tile.size, .y = y * Tile.size, .w = Tile.size, .h = Tile.size };
                if (box.overlaps(solid)) return true;
            }
        }
    }

    return false;
}

pub fn getTileAttribAtPixel(self: Room, attribs: []const Tile.Attrib, x: i32, y: i32) Tile.Attrib {
    const tx = @divFloor(x - self.bounds.x, Tile.size);
    const ty = @divFloor(y - self.bounds.y, Tile.size);
    return self.getTileAttribAtTile(attribs, tx, ty);
}

fn getTileAttribAtTile(self: Room, attribs: []const Tile.Attrib, tx: i32, ty: i32) Tile.Attrib {
    if (tx < 0 or ty < 0 or tx >= self.width or ty >= self.height) return .none;
    const ti = self.data[@as(usize, @intCast(ty * self.width + tx))];
    return attribs[ti];
}
