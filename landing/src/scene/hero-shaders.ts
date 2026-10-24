// The thread of tekhelet: two clouds of light (two people) drift, search for
// each other, then braid into a single thread as the page is scrolled.

export const heroVertex = /* glsl */ `
uniform float uTime;
uniform float uProgress;
uniform float uPixel;
uniform float uHalf;
uniform float uSpan;
uniform float uTilt;
uniform vec3 uMouse;
attribute vec3 aJit;
attribute vec4 aSeed; // delay, position along the thread, phase, strand (0 or 1)
varying float vAlpha;
varying float vStrand;
varying float vHeat;
const float PI = 3.14159265;

void main() {
  float strand = aSeed.w;
  float side = strand * 2.0 - 1.0;
  float phase = aSeed.z;

  // Cloud of one person: a soft mass that breathes and drifts.
  vec3 center = vec3(side * uSpan * 0.85, -side * 1.15, 0.0);
  vec3 drift = vec3(sin(uTime * 0.35 + phase * 6.283), cos(uTime * 0.28 + phase * 4.1), sin(uTime * 0.22 + phase * 2.7)) * 0.42;
  vec3 cloud = center + position * vec3(uSpan * 0.3, 1.2, 2.0) + drift;

  // The braid: two strands turning around a gently curved axis.
  float tt = aSeed.y * 2.0 - 1.0;
  float taper = 1.0 - pow(abs(tt), 6.0) * 0.9;
  float ang = tt * 6.4 + strand * PI + uTime * 0.45;
  float radius = (0.56 + 0.14 * sin(tt * 3.0 + uTime * 0.6)) * taper * min(1.0, uSpan / 5.5 + 0.34);
  vec3 braid = vec3(tt * uSpan, sin(tt * 1.9 + 0.6) * 0.42 + sin(ang) * radius, cos(ang) * radius);
  braid += aJit * (0.035 + 0.05 * taper);

  // Portrait screens: the thread runs along the tall axis.
  mat2 turn = mat2(cos(uTilt), sin(uTilt), -sin(uTilt), cos(uTilt));
  cloud.xy = turn * cloud.xy;
  braid.xy = turn * braid.xy;

  float p = clamp((uProgress - aSeed.x * 0.42) / 0.58, 0.0, 1.0);
  float e = p * p * p * (p * (p * 6.0 - 15.0) + 10.0);
  float swing = sin(e * PI);
  vec3 pos = mix(cloud, braid, e) + vec3(0.0, -side * swing * 1.5, side * swing * 1.3);

  // The pointer parts the light, lightly.
  vec2 away = pos.xy - uMouse.xy;
  float near = exp(-dot(away, away) * 0.9);
  pos.xy += normalize(away + vec2(1e-4)) * near * 0.4 * (0.35 + 0.65 * e);

  vec4 mv = modelViewMatrix * vec4(pos, 1.0);
  float depth = -mv.z;
  float blur = abs(depth - 9.0) / 5.0; // suggested depth of field
  float base = mix(1.5, 4.2, pow(fract(phase * 13.7), 1.6));
  gl_PointSize = base * uPixel * (1.0 + blur * 0.9) * (30.0 / depth) * mix(1.0, 0.8, e);
  gl_Position = projectionMatrix * mv;

  float ends = mix(1.0, smoothstep(1.0, 0.72, abs(tt)), e);
  vAlpha = mix(0.62, 1.0, e) * ends / (1.0 + blur * blur * 1.4);
  vStrand = strand;
  vHeat = e;
}
`;

export const heroFragment = /* glsl */ `
varying float vAlpha;
varying float vStrand;
varying float vHeat;

void main() {
  float d = length(gl_PointCoord - 0.5) * 2.0;
  if (d > 1.0) discard;
  float halo = pow(1.0 - d, 2.3);
  float core = pow(1.0 - d, 7.0);
  vec3 tekhelet = vec3(0.153, 0.278, 0.961);
  vec3 light = vec3(0.357, 0.471, 1.0);
  vec3 color = mix(light, tekhelet, vStrand * 0.6);
  color = mix(color, vec3(0.82, 0.88, 1.0), core * (0.5 + 0.5 * vHeat));
  gl_FragColor = vec4(color, (halo * 0.75 + core) * vAlpha);
}
`;
