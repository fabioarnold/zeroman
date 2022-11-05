precision mediump float;

uniform sampler2D u_map;
uniform vec2 u_map_size;
uniform sampler2D u_tiles;
uniform vec2 u_tiles_size;

varying vec2 v_texcoord;

void main() {
    const float bias = 0.125 / 16.0;
    float index = 255.5 * texture2D(u_map, v_texcoord).a;
    float tix = floor(mod(index, u_tiles_size.x)) + bias;
    float tiy = floor(index / u_tiles_size.x) + bias;
    float tx = mod(u_map_size.x * v_texcoord.x, 1.0) * (1.0 - 2.0 * bias);
    float ty = mod(u_map_size.y * v_texcoord.y, 1.0) * (1.0 - 2.0 * bias);
    float u = (tix + tx) / u_tiles_size.x;
    float v = (tiy + ty) / u_tiles_size.y;
    gl_FragColor = texture2D(u_tiles, vec2(u, v));
}