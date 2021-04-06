// Shaders
pub extern fn glInitShader(source: [*]const u8 , len: c_uint, type: c_uint) c_uint;
pub extern fn glLinkShaderProgram(vertexShaderId: c_uint, fragmentShaderId: c_uint) c_uint;

// GL
pub extern fn glViewport(_: c_int, _: c_int, _: c_int, _: c_int) void;
pub extern fn glClearColor(_: f32, _: f32, _: f32, _: f32) void;
pub extern fn glEnable(_: c_uint) void;
pub extern fn glDepthFunc(_: c_uint) void;
pub extern fn glBlendFunc(_: c_uint, _: c_uint) void;
pub extern fn glClear(_: c_uint) void;
pub extern fn glGetAttribLocation(_: c_uint, _: [*]const u8, _: c_uint) c_int;
pub extern fn glGetUniformLocation(_: c_uint, _: [*]const u8, _: c_uint) c_int;
pub extern fn glUniform4f(_: c_int, _: f32, _: f32, _: f32, _: f32) void;
pub extern fn glUniform1i(_: c_int, _: c_int) void;
pub extern fn glUniform1f(_: c_int, _: f32) void;
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
pub extern fn glDrawArrays(_: c_uint, _: c_uint, _: c_uint) void;
pub extern fn glCreateTexture() c_uint;
pub extern fn glGenTextures(_: c_int, _: [*c]c_uint) void;
pub extern fn glDeleteTextures(_: c_int, _: [*c]const c_uint) void;
pub extern fn glDeleteTexture(_: c_uint) void;
pub extern fn glBindTexture(_: c_uint, _: c_uint) void;
pub extern fn glTexImage2D(_: c_uint, _: c_uint, _: c_uint, _: c_int, _: c_int, _: c_uint, _: c_uint, _: c_uint, _: [*]const u8, _: c_uint) void;
pub extern fn glTexParameteri(_: c_uint, _: c_uint, _: c_uint) void;
pub extern fn glActiveTexture(_: c_uint) void;
pub extern fn glGetError() c_int;

// Types
pub const GLuint = c_uint;
pub const GLenum = c_uint;
pub const GLint = c_int;
pub const GLfloat = f32;

// Identifier constants pulled from WebGLRenderingContext
pub const GL_VERTEX_SHADER: c_uint = 35633;
pub const GL_FRAGMENT_SHADER: c_uint = 35632;
pub const GL_ARRAY_BUFFER: c_uint = 34962;
pub const GL_TRIANGLES: c_uint = 4;
pub const GL_TRIANGLE_STRIP = 5;
pub const GL_STATIC_DRAW: c_uint = 35044;
pub const GL_FLOAT: c_uint = 5126;
pub const GL_DEPTH_TEST: c_uint = 2929;
pub const GL_LEQUAL: c_uint = 515;
pub const GL_COLOR_BUFFER_BIT: c_uint = 16384;
pub const GL_DEPTH_BUFFER_BIT: c_uint = 256;
pub const GL_STENCIL_BUFFER_BIT = 1024;
pub const GL_TEXTURE_2D: c_uint = 3553;
pub const GL_RGBA: c_uint = 6408;
pub const GL_UNSIGNED_BYTE: c_uint = 5121;
pub const GL_TEXTURE_MAG_FILTER: c_uint = 10240;
pub const GL_TEXTURE_MIN_FILTER: c_uint = 10241;
pub const GL_NEAREST: c_uint = 9728;
pub const GL_TEXTURE0: c_uint = 33984;
pub const GL_BLEND: c_uint = 3042;
pub const GL_SRC_ALPHA: c_uint = 770;
pub const GL_ONE_MINUS_SRC_ALPHA: c_uint = 771;
pub const GL_ONE: c_uint= 1;
pub const GL_NO_ERROR = 0;
pub const GL_FALSE = 0;
pub const GL_TRUE = 1;
pub const GL_UNPACK_ALIGNMENT = 3317;

pub const GL_TEXTURE_WRAP_S = 10242;
pub const GL_CLAMP_TO_EDGE = 33071;
pub const GL_TEXTURE_WRAP_T = 10243;
pub const GL_PACK_ALIGNMENT = 3333;