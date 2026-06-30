/** @resolution */
uniform vec2 u_resolution;

/**
 * @label Grid Size
 * @default 26
 * @range 8, 64
 */
uniform float u_grid;

/**
 * @label Dot Color
 * @color
 * @default #2A313C
 */
uniform vec3 u_dot;

/**
 * @label Background
 * @color
 * @default #0E1116
 */
uniform vec3 u_bg;

void main() {
  vec2 p = mod(gl_FragCoord.xy, u_grid);
  float d = distance(p, vec2(u_grid * 0.5));
  float dot = 1.0 - smoothstep(1.1, 1.9, d);
  vec3 col = mix(u_bg, u_dot, dot * 0.9);
  gl_FragColor = vec4(col, 1.0);
}
