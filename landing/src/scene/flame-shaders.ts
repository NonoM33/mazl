// Shaders of the chabbat candles: a teardrop flame drawn per pixel (white core,
// yellow body, orange rim, faint blue base), its soft halo, and translucent wax
// lit from the flame above.

const NOISE = /* glsl */ `
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
  float sum = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < 4; i++) {
    sum += amplitude * noise(p);
    p *= 2.03;
    amplitude *= 0.5;
  }
  return sum;
}
`;

export const quadVertex = /* glsl */ `
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
`;

export const flameFragment = /* glsl */ `
uniform float uTime;
uniform float uSeed;
varying vec2 vUv;
${NOISE}

void main() {
  float y = vUv.y;
  float t = uTime + uSeed * 17.0;
  // Turbulence climbs the flame and bends it more towards the tip.
  float n = fbm(vec2(vUv.x * 2.6 + uSeed, y * 3.2 - t * 2.4));
  float sway = sin(t * 1.7) * 0.05 + sin(t * 4.3 + 1.3) * 0.025;
  float x = (vUv.x - 0.5) * 2.0 - (sway + (n - 0.5) * 0.42) * y * y * 1.6;

  // Teardrop profile: round at the base, widest low, drawn to a point.
  float w = 2.7 * pow(max(y, 0.0), 0.42) * pow(max(1.0 - y, 0.0), 1.35);
  float d = abs(x) / max(w, 0.001);

  float body = 1.0 - smoothstep(0.55, 1.0, d);
  body *= smoothstep(0.0, 0.05, y) * (1.0 - smoothstep(0.62 + n * 0.22, 0.98, y));
  float core = (1.0 - smoothstep(0.0, 0.6, d)) * smoothstep(0.03, 0.16, y) * (1.0 - smoothstep(0.22, 0.62, y));
  float blue = (1.0 - smoothstep(0.02, 0.2, y)) * (1.0 - smoothstep(0.25, 0.95, d)) * smoothstep(0.0, 0.03, y);

  vec3 rim = vec3(1.0, 0.42, 0.08);
  vec3 bodyColor = vec3(1.0, 0.74, 0.28);
  vec3 hot = vec3(1.0, 0.97, 0.88);
  vec3 color = mix(rim, bodyColor, smoothstep(0.95, 0.35, d));
  color = mix(color, hot, core);
  color = mix(color, vec3(0.3, 0.45, 1.0), blue * 0.55);

  float alpha = clamp(body * 0.95 + core * 0.4 + blue * 0.35, 0.0, 1.0);
  gl_FragColor = vec4(color * alpha, alpha);
}
`;

export const glowFragment = /* glsl */ `
uniform float uTime;
uniform float uSeed;
uniform float uStrength;
varying vec2 vUv;
${NOISE}

void main() {
  vec2 p = (vUv - 0.5) * 2.0;
  p.y *= 0.8;
  float r = length(p);
  float flicker = 0.86 + 0.14 * noise(vec2(uTime * 7.0 + uSeed * 31.0, uSeed));
  float glow = exp(-r * 4.2) * 0.9 + exp(-r * 1.6) * 0.22;
  vec3 color = vec3(1.0, 0.66, 0.26);
  float alpha = glow * flicker * uStrength;
  gl_FragColor = vec4(color * alpha, alpha);
}
`;

export const waxVertex = /* glsl */ `
varying vec3 vNormal;
varying vec3 vWorld;
varying vec3 vView;
void main() {
  vec4 world = modelMatrix * vec4(position, 1.0);
  vWorld = world.xyz;
  vNormal = normalize(mat3(modelMatrix) * normal);
  vView = normalize(cameraPosition - world.xyz);
  gl_Position = projectionMatrix * viewMatrix * world;
}
`;

export const waxFragment = /* glsl */ `
uniform vec3 uFlame;
uniform float uTop;
uniform float uTime;
uniform float uSeed;
varying vec3 vNormal;
varying vec3 vWorld;
varying vec3 vView;
${NOISE}

void main() {
  vec3 n = normalize(vNormal);
  vec3 toFlame = uFlame - vWorld;
  float distance = length(toFlame);
  float lambert = max(dot(n, toFlame / distance), 0.0);
  float flicker = 0.88 + 0.12 * noise(vec2(uTime * 7.0 + uSeed * 31.0, uSeed));

  vec3 wax = vec3(0.95, 0.92, 0.86);
  vec3 shadow = vec3(0.26, 0.22, 0.19);
  float depth = uTop - vWorld.y;
  // Light from the flame falls off down the candle; wax glows just under the top.
  float lit = lambert * flicker * 2.6 / (1.0 + distance * distance * 0.45);
  float subsurface = exp(-max(depth, 0.0) * 2.2) * 0.75 * flicker;
  float facing = pow(max(dot(n, normalize(vView)), 0.0), 0.6);
  vec3 color = mix(shadow, wax, clamp(lit + 0.22, 0.0, 1.0)) * mix(0.62, 1.0, facing);
  color += vec3(1.0, 0.62, 0.25) * subsurface * mix(0.6, 1.0, facing);
  // Faint vertical streaks of poured wax.
  color *= 0.94 + 0.06 * noise(vec2(atan(n.z, n.x) * 6.0, vWorld.y * 0.6));
  // The top is a melted pool lit from the wick.
  float cap = smoothstep(0.7, 0.95, n.y);
  color = mix(color, vec3(1.0, 0.78, 0.45) * (0.75 + 0.25 * flicker), cap * 0.85);
  gl_FragColor = vec4(color, 1.0);
}
`;
