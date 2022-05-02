// Types
pub const GLuint = c_uint;
pub const GLsizei = c_uint;
pub const GLenum = c_uint;
pub const GLint = c_int;
pub const GLfloat = f32;
pub const GLclampf = f32;

// Shaders
pub extern fn glInitShader(source: [*c]const u8 , len: c_uint, type: c_uint) c_uint;
pub extern fn glLinkShaderProgram(vertexShaderId: c_uint, fragmentShaderId: c_uint) c_uint;

// Textures
pub extern fn glLoadTexture(url: [*]const u8 , len: c_uint) c_uint;

// GL
pub extern fn glViewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei) void;
pub extern fn glClearColor(red: GLclampf, green: GLclampf, blue: GLclampf, alpha: GLclampf) void;
pub extern fn glEnable(_: c_uint) void;
pub extern fn glDepthFunc(_: c_uint) void;
pub extern fn glBlendFunc(_: c_uint, _: c_uint) void;
pub extern fn glClear(_: c_uint) void;
pub extern fn glGetAttribLocation(_: c_uint, _: [*]const u8, _: c_uint) c_int;
pub extern fn glGetUniformLocation(_: c_uint, _: [*]const u8, _: c_uint) c_int;
pub extern fn glUniform1i(location: GLint, _: c_int) void;
pub extern fn glUniform1f(location: GLint, _: f32) void;
pub extern fn glUniform2f(location: GLint, _: f32, _: f32) void;
pub extern fn glUniform4f(location: GLint, _: f32, _: f32, _: f32, _: f32) void;
pub extern fn glUniformMatrix4fv(_: c_int, _: c_int, _: c_uint, _: [*]const f32) void;
pub extern fn glCreateVertexArray() c_uint;
pub extern fn glGenVertexArrays(_: c_int, [*c]c_uint) void;
pub extern fn glDeleteVertexArrays(_: c_int, [*c]c_uint) void;
pub extern fn glBindVertexArray(_: c_uint) void;
pub extern fn glCreateBuffer() c_uint;
pub extern fn glGenBuffers(_: c_int, _: [*c]c_uint) void;
pub extern fn glDeleteBuffers(_: c_int, _: [*c]c_uint) void;
pub extern fn glDeleteBuffer(_: c_uint) void;
pub extern fn glBindBuffer(_: c_uint, _: c_uint) void;
pub extern fn glBufferData(_: c_uint, _: c_uint, _: [*c]const f32, _: c_uint) void;
pub extern fn glPixelStorei(_: c_uint, _: c_int) void;
pub extern fn glAttachShader(_: c_uint, _: c_uint) void;
pub extern fn glDetachShader(_: c_uint, _: c_uint) void;
pub extern fn glDeleteShader(_: c_uint) void;
pub extern fn glUseProgram(_: c_uint) void;
pub extern fn glDeleteProgram(_: c_uint) void;
pub extern fn glEnableVertexAttribArray(_: c_uint) void;
pub extern fn glVertexAttribPointer(_: c_uint, _: c_uint, _: c_uint, _: c_uint, _: c_uint, _: [*c]const c_uint) void;
pub extern fn glDrawArrays(mode: GLenum, first: GLint, count: GLsizei) void;
pub extern fn glCreateTexture() GLuint;
pub extern fn glGenTextures(n: GLsizei, textures: [*c]GLuint) void;
pub extern fn glDeleteTextures(n: GLsizei, textures: [*c]const GLuint) void;
pub extern fn glDeleteTexture(texture: GLuint) void;
pub extern fn glBindTexture(target: GLenum, texture: GLuint) void;
pub extern fn glTexImage2D(target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: GLenum, type: GLenum, data: [*c]const u8, data_len: c_uint) void;
pub extern fn glTexSubImage2D(target: GLenum, level: GLint, xoffset: GLint, yoffset:GLint, width: GLsizei, height: GLsizei, format: GLenum, type: GLenum, data: [*c]const u8) void;
pub extern fn glTexParameteri(target: GLenum, pname: GLenum, param: GLint) void;
pub extern fn glActiveTexture(texture: GLenum) void;
pub extern fn glGenFramebuffers(_: c_int, _: [*c]c_uint) void;
pub extern fn glBindFramebuffer(_: c_uint, _: c_uint) void;
pub extern fn glFramebufferTexture2D(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLenum, level: GLint) void;
pub extern fn glGetError() GLenum;
pub extern fn glPrintError() void;

// Identifier constants pulled from WebGLRenderingContext
pub const GL_DEPTH_BUFFER_BIT: c_uint = 256;
pub const GL_STENCIL_BUFFER_BIT = 1024;
pub const GL_COLOR_BUFFER_BIT: c_uint = 16384;

pub const GL_NO_ERROR = 0;
pub const GL_FALSE = 0;
pub const GL_TRUE = 1;
pub const GL_ONE: c_uint = 1;
pub const GL_TRIANGLES: c_uint = 4;
pub const GL_TRIANGLE_STRIP = 5;
pub const GL_LEQUAL: c_uint = 515;
pub const GL_SRC_ALPHA: c_uint = 770;
pub const GL_ONE_MINUS_SRC_ALPHA: c_uint = 771;
pub const GL_DEPTH_TEST: c_uint = 2929;
pub const GL_BLEND: c_uint = 3042;
pub const GL_UNPACK_ALIGNMENT = 3317;
pub const GL_PACK_ALIGNMENT = 3333;
pub const GL_TEXTURE_2D: c_uint = 3553;
pub const GL_UNSIGNED_BYTE: c_uint = 5121;
pub const GL_FLOAT: c_uint = 5126;
pub const GL_RED: c_uint = 6403;
pub const GL_ALPHA: c_uint = 6406;
pub const GL_RGB: c_uint = 6407;
pub const GL_RGBA: c_uint = 6408;
pub const GL_NEAREST: c_uint = 9728;
pub const GL_TEXTURE_MAG_FILTER: c_uint = 10240;
pub const GL_TEXTURE_MIN_FILTER: c_uint = 10241;
pub const GL_TEXTURE_WRAP_S = 10242;
pub const GL_TEXTURE_WRAP_T = 10243;
pub const GL_CLAMP_TO_EDGE = 33071;
pub const GL_TEXTURE0: c_uint = 33984;
pub const GL_TEXTURE1: c_uint = 33985;
pub const GL_ARRAY_BUFFER: c_uint = 34962;
pub const GL_STATIC_DRAW: c_uint = 35044;
pub const GL_FRAGMENT_SHADER: c_uint = 35632;
pub const GL_VERTEX_SHADER: c_uint = 35633;
pub const GL_FRAMEBUFFER = 36160;
pub const GL_COLOR_ATTACHMENT0 = 36064;