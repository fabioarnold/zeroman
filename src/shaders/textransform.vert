#version 300 es

precision mediump float;

uniform mat4 u_mvp;
uniform mat4 u_texmat;

// attribute vec2 a_position;

out vec2 v_texcoord;

void main() {
	vec2 coords[4];
	coords[0] = vec2(0, 0);
	coords[1] = vec2(1, 0);
	coords[2] = vec2(0, 1);
	coords[3] = vec2(1, 1);

	vec2 coord = coords[gl_VertexID];
	v_texcoord = (u_texmat * vec4(coord, 0, 1)).xy;
	gl_Position = u_mvp * vec4(coord, 0, 1);
}