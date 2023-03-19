#version 300 es

precision mediump float;

uniform sampler2D u_tex;

in vec2 v_texcoord;
out vec4 fragColor;

void main() {
	fragColor = texture(u_tex, v_texcoord);
}