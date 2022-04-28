const std = @import("std");
const za = @import("zalgebra");
const Vec2 = za.Vec2;
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;
const gl = @import("webgl.zig");

const keys = @import("keys.zig");
const web = @import("web.zig");

const Renderer = @import("Renderer.zig");
const Box = @import("Box.zig");
const Tile = @import("Tile.zig");
const Room = @import("Room.zig");
const Stage = @import("Stage.zig");
const Player = @import("Player.zig");
const needleman = @import("stages/needleman.zig").needleman;

const screen_width = 256;
const screen_height = 240;

const projection = za.orthographic(0, screen_width, screen_height, 0, -1, 1);

var player_sprite: Renderer.Sprite = undefined;
var door_sprite: Renderer.Sprite = undefined;
var tiles_tex: Renderer.Texture = undefined;
var prev_room_tex: Renderer.Texture = undefined;
var cur_room_tex: Renderer.Texture = undefined;
var font_tex: Renderer.Texture = undefined;
var text_tex: Renderer.Texture = undefined;
var text_buffer: [screen_width / 8 * screen_height / 8]u8 = undefined;

const GameData = struct {
    player: Player,
    prev_input: Player.Input,

    cur_room_index: u8 = 0,
    prev_room_index: u8 = 0,
    door1_h: u8 = 4,
    door2_h: u8 = 4,
};

var cur_stage: Stage = needleman;

var scrollr = Box{
    .x = 0,
    .y = 0,
    .w = screen_width,
    .h = screen_height,
};

var game_data = GameData{
    .player = Player{
        .box = Box{
            .x = 128 - 8,
            .y = 432 - 24 - 32,
            .w = 16,
            .h = 24,
        },
        .vx = 0,
        .vy = 0,
        .state = .idle,
        .sprite = undefined,
    },
    .prev_input = std.mem.zeroes(Player.Input),
};

export fn onInit() void {
    Renderer.init();
    game_data.player.load();
    door_sprite.load("img/door.png", 16, 16);
    scrollr.x = cur_stage.rooms[game_data.cur_room_index].bounds.x;
    scrollr.y = cur_stage.rooms[game_data.cur_room_index].bounds.y;

    const tiles_tex_url = "img/needleman.png";
    tiles_tex.handle = gl.glLoadTexture(tiles_tex_url, tiles_tex_url.len);
    tiles_tex.size = Vec2.new(12, 11);
    gl.glBindTexture(gl.GL_TEXTURE_2D, tiles_tex.handle);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
    uploadRoomTexture(&cur_room_tex, cur_stage.rooms[game_data.cur_room_index]);

    const font_tex_url = "img/font.png";
    font_tex.handle = gl.glLoadTexture(font_tex_url, font_tex_url.len);
    font_tex.size = Vec2.new(16, 8);
    gl.glBindTexture(gl.GL_TEXTURE_2D, font_tex.handle);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
    std.mem.set(u8, &text_buffer, ' ');
    const text_x = 32 / 2 - 2;
    const text_y = 30 / 2;
    _ = std.fmt.bufPrint(text_buffer[32 * text_y + text_x ..], "READY", .{}) catch unreachable;
    text_tex = createTextTexture(&text_buffer, screen_width / 8, screen_height / 8);
}

fn uploadRoomTexture(texture: *Renderer.Texture, room: Room) void {
    gl.glGenTextures(1, &texture.handle);
    gl.glBindTexture(gl.GL_TEXTURE_2D, texture.handle);
    texture.size = Vec2.new(@intToFloat(f32, room.width), @intToFloat(f32, room.height));
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_ALPHA, room.width, room.height, 0, gl.GL_ALPHA, gl.GL_UNSIGNED_BYTE, room.data[0..].ptr, room.data.len);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
}

fn createTextTexture(text: []u8, w: u32, h: u32) Renderer.Texture {
    var texture: Renderer.Texture = undefined;
    gl.glGenTextures(1, &texture.handle);
    texture.size = Vec2.new(@intToFloat(f32, w), @intToFloat(f32, h));
    gl.glBindTexture(gl.GL_TEXTURE_2D, texture.handle);
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_ALPHA, w, h, 0, gl.GL_ALPHA, gl.GL_UNSIGNED_BYTE, text.ptr, text.len);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
    return texture;
}

export fn onResize(width: c_uint, height: c_uint, scale: f32) void {
    Renderer.resize(@intToFloat(f32, width), @intToFloat(f32, height), scale);
}

var cam_x: f32 = 0;
var cam_y: f32 = 0;
export fn onKeyDown(key: c_uint) void {
    switch (key) {
        keys.KEY_LEFT => cam_x -= 1.0,
        keys.KEY_RIGHT => cam_x += 1.0,
        keys.KEY_DOWN => cam_y += 1.0,
        keys.KEY_UP => cam_y -= 1.0,
        else => {},
    }
}

fn updatePlayer(player: *Player) void {
    player.tick();

    const room = cur_stage.rooms[game_data.cur_room_index];
    const player_old_x = player.box.x;

    const input = Player.Input.scanKeyboard().combine(Player.Input.scanGamepad());
    player.handleInput(room, cur_stage.attribs, input, game_data.prev_input);
    game_data.prev_input = input;

    // scrolling
    if (player.box.x != player_old_x) {
        const diff_x = player.box.x - player_old_x;
        const target_x = player.box.x + 8 - screen_width / 2;
        if (scrollr.x < target_x and diff_x > 0) scrollr.x += diff_x;
        if (scrollr.x > target_x and diff_x < 0) scrollr.x += diff_x;
    }
    if (scrollr.x < room.bounds.x) scrollr.x = room.bounds.x;
    if (scrollr.x > room.bounds.x + room.bounds.w - screen_width) scrollr.x = room.bounds.x + room.bounds.w - screen_width;
}

const RoomTransition = enum(u8) {
    none,
    vertical,
    door_ltr,
    door_rtl,
};

const door_duration = 16;
var room_transition: RoomTransition = .none;
var mode_frame: i32 = 0;

fn tick() void {
    if (room_transition == .vertical) { // room transition
        mode_frame += 1;
        const cur_room = cur_stage.rooms[game_data.cur_room_index];
        const prev_room = cur_stage.rooms[game_data.prev_room_index];
        if (cur_room.bounds.y >= prev_room.bounds.y + prev_room.bounds.h) {
            // scroll down
            scrollr.y = prev_room.bounds.y + @divTrunc(mode_frame * screen_height, 60);
            game_data.player.box.y = cur_room.bounds.y - game_data.player.box.h + @divTrunc(mode_frame * game_data.player.box.h, 60);
        }
        if (cur_room.bounds.y + cur_room.bounds.h <= prev_room.bounds.y) {
            // scroll up
            scrollr.y = prev_room.bounds.y - @divTrunc(mode_frame * screen_height, 60);
            game_data.player.box.y = prev_room.bounds.y - @divTrunc(mode_frame * game_data.player.box.h, 60);
        }
        if (mode_frame == 60) {
            //player.vy = 0;
            room_transition = .none;
        }
    } else if (room_transition == .door_ltr) {
        mode_frame += 1;
        if (mode_frame <= door_duration) {
            game_data.door1_h = 4 - @intCast(u8, @divTrunc(4 * mode_frame, door_duration));
        } else if (mode_frame <= door_duration + 64) {
            game_data.player.tick();
            const cur_room = cur_stage.rooms[game_data.cur_room_index];
            // const prev_room = cur_stage.rooms[game_data.prev_room_index];
            scrollr.x = cur_room.bounds.x - screen_width + @divTrunc((mode_frame - door_duration) * screen_width, 64);
            game_data.player.box.x = cur_room.bounds.x - 2 * game_data.player.box.w + @divTrunc(3 * game_data.player.box.w * (mode_frame - door_duration), 64);
        } else if (mode_frame <= door_duration + 64 + door_duration) {
            game_data.door1_h = @intCast(u8, @divTrunc(4 * (mode_frame - 64 - door_duration), door_duration));
        }
        if (mode_frame == door_duration + 64 + door_duration) {
            room_transition = .none;
        }
    } else if (room_transition == .door_rtl) {
        mode_frame += 1;
        if (mode_frame <= door_duration) {
            game_data.door2_h = 4 - @intCast(u8, @divTrunc(4 * mode_frame, door_duration));
        } else if (mode_frame <= door_duration + 64) {
            game_data.player.tick();
            // const cur_room = cur_stage.rooms[game_data.cur_room_index];
            const prev_room = cur_stage.rooms[game_data.prev_room_index];
            scrollr.x = prev_room.bounds.x - @divTrunc((mode_frame - door_duration) * screen_width, 64);
            game_data.player.box.x = prev_room.bounds.x + game_data.player.box.w - @divTrunc(3 * game_data.player.box.w * (mode_frame - door_duration), 64);
        } else if (mode_frame <= door_duration + 64 + door_duration) {
            game_data.door2_h = @intCast(u8, @divTrunc(4 * (mode_frame - 64 - door_duration), door_duration));
        }
        if (mode_frame == door_duration + 64 + door_duration) {
            room_transition = .none;
        }
    } else {
        updatePlayer(&game_data.player);

        if (findNextRoom(cur_stage.rooms, game_data.cur_room_index, game_data.player.box)) |next_room_index| {
            setNextRoom(next_room_index);
            room_transition = .vertical;
            mode_frame = 0;
        }

        const cur_room = cur_stage.rooms[game_data.cur_room_index];

        // check door 1
        if (cur_room.door1_y != 0xFF) {
            var door_box = Box{
                .x = cur_room.bounds.x,
                .y = cur_room.bounds.y + @intCast(i32, cur_room.door1_y) * Tile.size,
                .w = Tile.size,
                .h = 4 * Tile.size,
            };
            if (game_data.player.box.overlap(door_box)) {
                door_box.x -= 1;
                if (findNextRoom(cur_stage.rooms, game_data.cur_room_index, door_box)) |next_room_index| {
                    setNextRoom(next_room_index);
                    room_transition = .door_rtl;
                    mode_frame = 0;
                }
            }
        }

        // check door 2
        if (cur_room.door2_y != Room.no_door) {
            var door_box = Box{
                .x = cur_room.bounds.x + cur_room.bounds.w - Tile.size,
                .y = cur_room.bounds.y + @intCast(i32, cur_room.door2_y) * Tile.size,
                .w = Tile.size,
                .h = 4 * Tile.size,
            };
            if (game_data.player.box.overlap(door_box)) {
                door_box.x += 1;
                if (findNextRoom(cur_stage.rooms, game_data.cur_room_index, door_box)) |next_room_index| {
                    setNextRoom(next_room_index);
                    room_transition = .door_ltr;
                    mode_frame = 0;
                }
            }
        }
    }
}

// Find a room which overlaps box
fn findNextRoom(rooms: []const Room, skip_room_index: u8, box: Box) ?u8 {
    var room_index: u8 = 0;
    while (room_index < rooms.len) : (room_index += 1) {
        if (room_index == skip_room_index) continue;
        if (rooms[room_index].bounds.overlap(box)) {
            return room_index;
        }
    }
    return null;
}

fn setNextRoom(next_room_index: u8) void {
    game_data.prev_room_index = game_data.cur_room_index;
    game_data.cur_room_index = next_room_index;
    // TODO: free prev_room_tex
    prev_room_tex = cur_room_tex;
    uploadRoomTexture(&cur_room_tex, cur_stage.rooms[game_data.cur_room_index]);
}

fn draw() void {
    Renderer.clear();

    var context: Renderer.RenderContext = undefined;
    context.projection = projection;

    // texture issue at 0.5
    context.view = Mat4.fromTranslate(Vec3.new(@intToFloat(f32, -scrollr.x), @intToFloat(f32, -scrollr.y), 0));

    // prev room is visible during transition
    if (room_transition == .vertical or room_transition == .door_ltr or room_transition == .door_rtl) {
        drawRoom(cur_stage.rooms[game_data.prev_room_index], context, prev_room_tex, game_data.door2_h, game_data.door1_h);
    }

    drawRoom(cur_stage.rooms[game_data.cur_room_index], context, cur_room_tex, game_data.door1_h, game_data.door2_h);

    game_data.player.draw(context);

    const mvp = projection.mul(Mat4.fromScale(Vec3.new(screen_width, screen_height, 0)));
    Renderer.drawTilemap(mvp, text_tex, font_tex);
}

fn drawRoom(room: Room, context: Renderer.RenderContext, room_tex: Renderer.Texture, door1_h: u8, door2_h: u8) void {
    const bounds = room.bounds;
    const offset = Vec3.new(@intToFloat(f32, bounds.x), @intToFloat(f32, bounds.y), 0);
    const size = Vec3.new(@intToFloat(f32, bounds.w), @intToFloat(f32, bounds.h), 0);
    const model = Mat4.fromTranslate(offset).mul(Mat4.fromScale(size));
    const mvp = projection.mul(context.view.mul(model));
    Renderer.drawTilemap(mvp, room_tex, tiles_tex);

    if (room.door1_y != Room.no_door) {
        var i: usize = 0;
        while (i < door1_h) : (i += 1) {
            const dst_rect = Renderer.Rect2.new(
                @intToFloat(f32, room.bounds.x),
                @intToFloat(f32, @intCast(u32, room.bounds.y) + (room.door1_y + i) * Tile.size),
                Tile.size,
                Tile.size,
            );
            door_sprite.draw(context, Renderer.Rect2.new(0, 0, Tile.size, Tile.size), dst_rect);
        }
    }
    if (room.door2_y != Room.no_door) {
        var i: usize = 0;
        while (i < door2_h) : (i += 1) {
            const dst_rect = Renderer.Rect2.new(
                @intToFloat(f32, room.bounds.x + room.bounds.w - Tile.size),
                @intToFloat(f32, @intCast(u32, room.bounds.y) + (room.door2_y + i) * Tile.size),
                Tile.size,
                Tile.size,
            );
            door_sprite.draw(context, Renderer.Rect2.new(0, 0, Tile.size, Tile.size), dst_rect);
        }
    }
}

export fn onAnimationFrame() void {
    tick();
    Renderer.beginDraw();
    draw();
    Renderer.endDraw();
}
