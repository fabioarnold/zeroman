const gl = @import("webgl.zig");

var video_width: f32 = 1280;
var video_height: f32 = 720;
var video_scale: f32 = 1;
const fb_width = 256;
const fb_height = 240;
var fbo: gl.GLuint = undefined;
var fbo_tex: gl.GLuint = undefined;
var blit_vbo: gl.GLuint = undefined;

pub var scroll: Vec2 = Vec2.init(0, 0);

const identity_matrix = [16]f32{
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
};

var blit_scaled: struct {
    program: gl.GLuint,
    scale_loc: gl.GLint,
} = undefined;

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

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Vec2 {
        return Vec2{ .x = x, .y = y };
    }
};

pub const Rect2 = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,

    pub fn init(x: f32, y: f32, w: f32, h: f32) Rect2 {
        return Rect2{ .x = x, .y = y, .w = w, .h = h };
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
    pub fn draw(sprite: Texture, src_rect: Rect2, dst_rect: Rect2) void {
        const x = dst_rect.x - scroll.x;
        const y = dst_rect.y - scroll.y;
        const px = 2.0 / @as(f32, fb_width);
        const py: f32 = 2.0 / @as(f32, fb_height);
        const mvp = [16]f32{
            px * dst_rect.w, 0,                0, 0,
            0,               -py * dst_rect.h, 0, 0,
            0,               0,                1, 0,
            px * x - 1,      1 - py * y,       0, 1,
        };
        gl.glUseProgram(blit2d.program);
        gl.glUniformMatrix4fv(blit2d.mvp_loc, 1, gl.GL_FALSE, &mvp);

        const sx = 1.0 / @intToFloat(f32, sprite.width);
        const sy = 1.0 / @intToFloat(f32, sprite.height);
        const texmat = [16]f32{
            src_rect.w * sx, 0,               0, 0,
            0,               src_rect.h * sy, 0, 0,
            0,               0,               1, 0,
            src_rect.x * sx, src_rect.y * sy, 0, 1,
        };
        gl.glUniformMatrix4fv(blit2d.texmat_loc, 1, gl.GL_FALSE, &texmat);
        gl.glBindTexture(gl.GL_TEXTURE_2D, sprite.handle);
        gl.glDrawArrays(gl.GL_TRIANGLE_STRIP, 4, 4);
    }
};

pub const Tilemap = struct {
    pub fn draw(map: Texture, tiles: Texture, rect: Rect2) void {
        const x = rect.x - scroll.x;
        const y = rect.y - scroll.y;
        const px = 2.0 / @as(f32, fb_width);
        const py: f32 = 2.0 / @as(f32, fb_height);
        const mvp = [16]f32{
            px * rect.w, 0,            0, 0,
            0,           -py * rect.h, 0, 0,
            0,           0,            1, 0,
            px * x - 1,  1 - py * y,   0, 1,
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
    pub fn drawRect(rect: Rect2, color: Color) void {
        const x = rect.x - scroll.x;
        const y = rect.y - scroll.y;
        const px = 2.0 / @as(f32, fb_width);
        const py: f32 = 2.0 / @as(f32, fb_height);
        const mvp = [16]f32{
            px * rect.w, 0,            0, 0,
            0,           -py * rect.h, 0, 0,
            0,           0,            1, 0,
            px * x - 1,  1 - py * y,   0, 1,
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

    gl.glGenFramebuffers(1, &fbo);
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fbo);
    gl.glGenTextures(1, &fbo_tex);
    gl.glBindTexture(gl.GL_TEXTURE_2D, fbo_tex);
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, fb_width, fb_height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, null, 0);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, fbo_tex, 0);
    gl.glBindTexture(gl.GL_TEXTURE_2D, 0);
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0);

    const color_frag_src = @embedFile("shaders/color.frag");
    const tex_frag_src = @embedFile("shaders/tex.frag");
    const tiled_frag_src = @embedFile("shaders/tiled.frag");
    const transform_vert_src = @embedFile("shaders/transform.vert");
    const textransform_vert_src = @embedFile("shaders/textransform.vert");
    const scale_vert_src = @embedFile("shaders/scale.vert");
    colored.program = loadShader(transform_vert_src, color_frag_src);
    gl.glUseProgram(colored.program);
    colored.color_loc = gl.glGetUniformLocation(colored.program, "u_color", "u_color".len);
    colored.mvp_loc = gl.glGetUniformLocation(colored.program, "u_mvp", "u_mvp".len);
    blit2d.program = loadShader(textransform_vert_src, tex_frag_src);
    gl.glUseProgram(blit2d.program);
    blit2d.mvp_loc = gl.glGetUniformLocation(blit2d.program, "u_mvp", "u_mvp".len);
    blit2d.texmat_loc = gl.glGetUniformLocation(blit2d.program, "u_texmat", "u_texmat".len);
    blit_scaled.program = loadShader(scale_vert_src, tex_frag_src);
    gl.glUseProgram(blit_scaled.program);
    blit_scaled.scale_loc = gl.glGetUniformLocation(blit_scaled.program, "u_scale", "u_scale".len);
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

pub fn resize(width: f32, height: f32, scale: f32) void {
    video_width = width;
    video_height = height;
    video_scale = scale;
}

pub fn clear() void {
    gl.glClearColor(0.5, 0.5, 0.5, 1);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT);
}

pub fn beginDraw() void {
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fbo);
    gl.glViewport(0, 0, fb_width, fb_height);
}

pub fn endDraw() void {
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0);

    const fb_ar = @intToFloat(f32, fb_width) / @intToFloat(f32, fb_height);
    const video_ar = video_width / video_height;

    gl.glViewport(0, 0, @floatToInt(u32, video_scale * video_width), @floatToInt(u32, video_scale * video_height));
    gl.glClearColor(0, 0, 0, 0);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT);
    gl.glUseProgram(blit_scaled.program);
    if (fb_ar < video_ar) {
        gl.glUniform2f(blit_scaled.scale_loc, fb_ar / video_ar, 1.0);
    } else {
        gl.glUniform2f(blit_scaled.scale_loc, 1.0, video_ar / fb_ar);
    }
    gl.glBindTexture(gl.GL_TEXTURE_2D, fbo_tex);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, blit_vbo);
    gl.glVertexAttribPointer(0, 2, gl.GL_FLOAT, gl.GL_FALSE, 0, null);
    gl.glDrawArrays(gl.GL_TRIANGLE_STRIP, 0, 4);
}
