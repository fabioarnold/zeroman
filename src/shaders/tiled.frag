precision mediump float;

uniform sampler2D u_map;
uniform vec2 u_map_size;
uniform sampler2D u_tiles;
uniform vec2 u_tiles_size;

varying vec2 v_texcoord;

void main() {
    float index = 255.0 * texture2D(u_map, v_texcoord).a;
    if (index == 0.0) discard;
    index -= 0.5;

    float tix = floor(mod(index, u_tiles_size.x));
    float tiy = floor(index / u_tiles_size.x);
    float tx = mod(u_map_size.x * v_texcoord.x, 1.0);
    float ty = mod(u_map_size.y * v_texcoord.y, 1.0);
    float u = (tix + tx) / u_tiles_size.x;
    float v = (tiy + ty) / u_tiles_size.y;
    gl_FragColor = texture2D(u_tiles, vec2(u, v));
}