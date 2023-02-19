const gl = @import("webgl.zig");

const fb_width = 256;
const fb_height = 240;
var blit_vbo: gl.GLuint = undefined;

pub var scroll = Point.init(0, 0);

const identity_matrix = [16]f32{
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
};

var blit2d: struct {
    program: gl.GLuint,
    mvp_loc: gl.GLint,
    texmat_loc: gl.GLint,
} = undefined;

var tiled: struct {
    program: gl.GLuint,
    map_loc: gl.GLint,
    map_size_loc: gl.GLint,
    tiles_loc: gl.GLint,
    tiles_size_loc: gl.GLint,
    mvp_loc: gl.GLint,
    texmat_loc: gl.GLint,
} = undefined;

var colored: struct {
    program: gl.GLuint,
    color_loc: gl.GLint,
    mvp_loc: gl.GLint,
} = undefined;

pub const Point = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Point {
        return Point{ .x = x, .y = y };
    }
};

pub const Rect = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,

    pub fn init(x: i32, y: i32, w: i32, h: i32) Rect {
        return Rect{ .x = x, .y = y, .w = w, .h = h };
    }
};

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    pub fn init(r: f32, g: f32, b: f32, a: f32) Color {
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }
};

pub const Texture = struct {
    handle: gl.GLuint = 0,
    width: u32,
    height: u32,

    pub fn loadFromUrl(self: *Texture, url: []const u8, width: u32, height: u32) void {
        self.width = width;
        self.height = height;
        self.bind();
        gl.glTexImage2DUrl(self.handle, url.ptr, url.len);
    }

    pub fn loadFromData(self: *Texture, data: []const u8, width: u32, height: u32) void {
        self.width = width;
        self.height = height;
        self.bind();
        gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_ALPHA, width, height, 0, gl.GL_ALPHA, gl.GL_UNSIGNED_BYTE, data.ptr, data.len);
    }

    pub fn bind(self: *Texture) void {
        if (self.handle == 0) {
            gl.glGenTextures(1, &self.handle);
            gl.glBindTexture(gl.GL_TEXTURE_2D, self.handle);
            setDefaultParameters();
        } else {
            gl.glBindTexture(gl.GL_TEXTURE_2D, self.handle);
        }
    }

    pub fn updateData(self: *Texture, data: []const u8) void {
        self.bind();
        gl.glTexSubImage2D(gl.GL_TEXTURE_2D, 0, 0, 0, self.width, self.height, gl.GL_ALPHA, gl.GL_UNSIGNED_BYTE, data.ptr);
    }

    fn setDefaultParameters() void {
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
    }
};

pub const Sprite = struct {
    pub fn draw(sprite: Texture, x: i32, y: i32) void {
        const src_rect = Rect.init(0, 0, @intCast(i32, sprite.width), @intCast(i32, sprite.height));
        const dst_rect = Rect.init(x, y, src_rect.w, src_rect.h);
        drawFromTo(sprite, src_rect, dst_rect);
    }

    pub fn drawFrame(sprite: Texture, src_rect: Rect, x: i32, y: i32) void {
        const dst_rect = Rect.init(x, y, src_rect.w, src_rect.h);
        drawFromTo(sprite, src_rect, dst_rect);
    }

    pub fn drawFromTo(sprite: Texture, src_rect: Rect, dst_rect: Rect) void {
        const x = @intToFloat(f32, dst_rect.x - scroll.x);
        const y = @intToFloat(f32, dst_rect.y - scroll.y);
        const w = @intToFloat(f32, dst_rect.w);
        const h = @intToFloat(f32, dst_rect.h);
        const px: f32 = 2.0 / @as(f32, fb_width);
        const py: f32 = 2.0 / @as(f32, fb_height);
        const mvp = [16]f32{
            px * w,     0,          0, 0,
            0,          -py * h,    0, 0,
            0,          0,          1, 0,
            px * x - 1, 1 - py * y, 0, 1,
        };
        gl.glUseProgram(blit2d.program);
        gl.glUniformMatrix4fv(blit2d.mvp_loc, 1, gl.GL_FALSE, &mvp);

        const sx = 1.0 / @intToFloat(f32, sprite.width);
        const sy = 1.0 / @intToFloat(f32, sprite.height);
        const texmat = [16]f32{
            @intToFloat(f32, src_rect.w) * sx, 0,                                 0, 0,
            0,                                 @intToFloat(f32, src_rect.h) * sy, 0, 0,
            0,                                 0,                                 1, 0,
            @intToFloat(f32, src_rect.x) * sx, @intToFloat(f32, src_rect.y) * sy, 0, 1,
        };
        gl.glUniformMatrix4fv(blit2d.texmat_loc, 1, gl.GL_FALSE, &texmat);
        gl.glBindTexture(gl.GL_TEXTURE_2D, sprite.handle);
        gl.glDrawArrays(gl.GL_TRIANGLE_STRIP, 4, 4);
    }
};

pub const Tilemap = struct {
    pub fn draw(map: Texture, tiles: Texture, rect: Rect) void {
        const x = @intToFloat(f32, rect.x - scroll.x);
        const y = @intToFloat(f32, rect.y - scroll.y);
        const w = @intToFloat(f32, rect.w);
        const h = @intToFloat(f32, rect.h);
        const px = 2.0 / @as(f32, fb_width);
        const py: f32 = 2.0 / @as(f32, fb_height);
        const mvp = [16]f32{
            px * w,     0,          0, 0,
            0,          -py * h,    0, 0,
            0,          0,          1, 0,
            px * x - 1, 1 - py * y, 0, 1,
        };
        gl.glUseProgram(tiled.program);
        gl.glUniformMatrix4fv(tiled.mvp_loc, 1, gl.GL_FALSE, &mvp);
        gl.glUniformMatrix4fv(tiled.texmat_loc, 1, gl.GL_FALSE, &identity_matrix);
        gl.glUniform1i(tiled.map_loc, 0);
        gl.glUniform2f(tiled.map_size_loc, @intToFloat(f32, map.width), @intToFloat(f32, map.height));
        gl.glUniform1i(tiled.tiles_loc, 1);
        gl.glUniform2f(tiled.tiles_size_loc, @intToFloat(f32, tiles.width), @intToFloat(f32, tiles.height));

        gl.glActiveTexture(gl.GL_TEXTURE1);
        gl.glBindTexture(gl.GL_TEXTURE_2D, tiles.handle);
        gl.glActiveTexture(gl.GL_TEXTURE0);
        gl.glBindTexture(gl.GL_TEXTURE_2D, map.handle);
        gl.glDrawArrays(gl.GL_TRIANGLE_STRIP, 4, 4);
    }
};

pub const Debug = struct {
    pub fn drawRect(rect: Rect, color: Color) void {
        const x = @intToFloat(f32, rect.x - scroll.x);
        const y = @intToFloat(f32, rect.y - scroll.y);
        const w = @intToFloat(f32, rect.w);
        const h = @intToFloat(f32, rect.h);
        const px = 2.0 / @as(f32, fb_width);
        const py: f32 = 2.0 / @as(f32, fb_height);
        const mvp = [16]f32{
            px * w,     0,          0, 0,
            0,          -py * h,    0, 0,
            0,          0,          1, 0,
            px * x - 1, 1 - py * y, 0, 1,
        };
        gl.glUseProgram(colored.program);
        gl.glUniformMatrix4fv(colored.mvp_loc, 1, gl.GL_FALSE, &mvp);
        gl.glUniform4f(colored.color_loc, color.r, color.g, color.b, color.a);
        gl.glDrawArrays(gl.GL_TRIANGLE_STRIP, 4, 4);
    }
};

fn loadShader(vert_src: []const u8, frag_src: []const u8) gl.GLuint {
    const vert_shader = gl.glInitShader(vert_src.ptr, vert_src.len, gl.GL_VERTEX_SHADER);
    const frag_shader = gl.glInitShader(frag_src.ptr, frag_src.len, gl.GL_FRAGMENT_SHADER);
    return gl.glLinkShaderProgram(vert_shader, frag_shader);
}

pub fn init() void {
    gl.glEnable(gl.GL_BLEND);
    gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA);

    const color_frag_src = @embedFile("shaders/color.frag");
    const tex_frag_src = @embedFile("shaders/tex.frag");
    const tiled_frag_src = @embedFile("shaders/tiled.frag");
    const transform_vert_src = @embedFile("shaders/transform.vert");
    const textransform_vert_src = @embedFile("shaders/textransform.vert");
    colored.program = loadShader(transform_vert_src, color_frag_src);
    gl.glUseProgram(colored.program);
    colored.color_loc = gl.glGetUniformLocation(colored.program, "u_color", "u_color".len);
    colored.mvp_loc = gl.glGetUniformLocation(colored.program, "u_mvp", "u_mvp".len);
    blit2d.program = loadShader(textransform_vert_src, tex_frag_src);
    gl.glUseProgram(blit2d.program);
    blit2d.mvp_loc = gl.glGetUniformLocation(blit2d.program, "u_mvp", "u_mvp".len);
    blit2d.texmat_loc = gl.glGetUniformLocation(blit2d.program, "u_texmat", "u_texmat".len);
    tiled.program = loadShader(textransform_vert_src, tiled_frag_src);
    gl.glUseProgram(tiled.program);
    tiled.map_loc = gl.glGetUniformLocation(tiled.program, "u_map", "u_map".len);
    tiled.map_size_loc = gl.glGetUniformLocation(tiled.program, "u_map_size", "u_map_size".len);
    tiled.tiles_loc = gl.glGetUniformLocation(tiled.program, "u_tiles", "u_tiles".len);
    tiled.tiles_size_loc = gl.glGetUniformLocation(tiled.program, "u_tiles_size", "u_tiles_size".len);
    tiled.mvp_loc = gl.glGetUniformLocation(tiled.program, "u_mvp", "u_mvp".len);
    tiled.texmat_loc = gl.glGetUniformLocation(tiled.program, "u_texmat", "u_texmat".len);

    const triangles = [_]f32{
        -1.0, -1.0,
        1.0,  -1.0,
        -1.0, 1.0,
        1.0,  1.0,

        0.0,  0.0,
        0.0,  1.0,
        1.0,  0.0,
        1.0,  1.0,
    };
    gl.glGenBuffers(1, &blit_vbo);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, blit_vbo);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, triangles.len * @sizeOf(f32), &triangles, gl.GL_STATIC_DRAW);

    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, blit_vbo);
    gl.glEnableVertexAttribArray(0);
    gl.glVertexAttribPointer(0, 2, gl.GL_FLOAT, gl.GL_FALSE, 0, null);
}

pub fn clear() void {
    gl.glClearColor(0, 0, 0, 1);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT);
}
