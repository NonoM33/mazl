import { AdditiveBlending, BufferAttribute, BufferGeometry, PerspectiveCamera, Points, Scene, ShaderMaterial, Vector2 } from "three";
import { createPlayer } from "./player";
import { gaussian, seeded } from "./random";

export interface OutroScene {
  readonly dispose: () => void;
}

export interface OutroOptions {
  readonly canvas: HTMLCanvasElement;
  readonly animate: boolean;
  readonly lightweight: boolean;
  // Scroll progress of the closing sequence, 0 to 1.
  readonly progress: () => number;
  // The crisp HTML wordmark the particles land on, then hand over to.
  readonly target: HTMLElement;
}

const FOV = 40;
const DISTANCE = 8;
const SAMPLE_WIDTH = 1400;
const SAMPLE_HEIGHT = 440;

const vertex = /* glsl */ `
uniform float uTime;
uniform float uProgress;
uniform vec2 uCenter;
uniform float uWidth;
uniform float uAspect;
uniform float uFade;
uniform float uPixel;
attribute vec3 aStart;
attribute vec4 aSeed;
varying float vDot;
varying float vAlpha;
varying float vShine;

float easeInOut(float x) { return x < 0.5 ? 4.0 * x * x * x : 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0; }

void main() {
  // Each particle leaves a little later than the previous ones: the word builds up.
  // The flight runs between 30 % and 80 % of the sequence: every particle has
  // landed before the crisp wordmark fades in.
  float flight = clamp((uProgress - 0.3) / 0.5, 0.0, 1.0);
  float local = clamp((flight - aSeed.x * 0.35) / 0.65, 0.0, 1.0);
  float e = easeInOut(local);
  vec3 drift = vec3(sin(uTime * 0.3 + aSeed.y * 6.28), cos(uTime * 0.25 + aSeed.z * 6.28), sin(uTime * 0.2 + aSeed.x * 6.28)) * 0.35;
  vec3 from = aStart + drift;
  // position: (u, v) in the wordmark's line box, 0..1 from its top-left corner.
  vec3 to = vec3(uCenter.x + (position.x - 0.5) * uWidth, uCenter.y - (position.y - 0.5) * uWidth * uAspect, position.z);
  // A spiral on the way in, gone once the particle has landed.
  float swirl = sin(e * 3.14159) * (0.9 + aSeed.y * 0.8);
  float angle = e * 4.0 + aSeed.z * 6.28;
  vec3 pos = mix(from, to, e) + vec3(cos(angle), sin(angle), 0.0) * swirl * 0.45;
  pos += vec3(0.0, 0.0, sin(uTime * 1.3 + aSeed.y * 9.0) * 0.012 * e);

  vec4 mv = modelViewMatrix * vec4(pos, 1.0);
  float size = mix(1.4 + fract(aSeed.w) * 1.2, 2.5, e);
  gl_PointSize = size * uPixel * (34.0 / -mv.z);
  gl_Position = projectionMatrix * mv;

  vDot = aSeed.w > 1.5 ? 1.0 : 0.0;
  vAlpha = mix(0.28 + aSeed.y * 0.3, 0.8, e) * uFade;
  // A sheen sweeps across the word once it is written.
  float sweep = mod(uTime * 0.45, 2.6) - 1.3;
  vShine = smoothstep(0.7, 0.85, uProgress) * exp(-pow((position.x * 2.0 - 1.0 - sweep) * 6.0, 2.0));
}
`;

const fragment = /* glsl */ `
varying float vDot;
varying float vAlpha;
varying float vShine;
void main() {
  float d = length(gl_PointCoord - 0.5) * 2.0;
  if (d > 1.0) discard;
  float halo = pow(1.0 - d, 1.8);
  vec3 white = vec3(0.96, 0.97, 1.0);
  vec3 tekhelet = vec3(0.36, 0.47, 1.0);
  vec3 color = mix(white, tekhelet, vDot) + vShine * 0.8;
  gl_FragColor = vec4(color * halo * vAlpha, halo * vAlpha);
}
`;

interface Sampled {
  readonly letters: Float32Array;
  readonly dot: Float32Array;
  // Height of the line box over its width (line-height 1).
  readonly aspect: number;
}

const FONT_SIZE = 300;
// Same letter spacing as .outro__word, so the particles land on the real glyphs.
const LETTER_SPACING = -0.055 * FONT_SIZE;

// The wordmark "mazl." drawn exactly like the HTML one (Geist 700, line-height 1),
// read back pixel by pixel: each opaque pixel becomes a landing spot, expressed
// in the line box (u across, v down, both 0..1).
async function sampleWordmark(): Promise<Sampled> {
  const empty = { letters: new Float32Array(0), dot: new Float32Array(0), aspect: 1 };
  await document.fonts.load(`700 ${FONT_SIZE}px Geist`).catch(() => undefined);
  const canvas = document.createElement("canvas");
  canvas.width = SAMPLE_WIDTH;
  canvas.height = SAMPLE_HEIGHT;
  const ctx = canvas.getContext("2d", { willReadFrequently: true });
  if (ctx === null) return empty;
  ctx.font = `700 ${FONT_SIZE}px Geist, ui-sans-serif, system-ui, sans-serif`;
  if ("letterSpacing" in ctx) ctx.letterSpacing = `${LETTER_SPACING}px`;
  ctx.textBaseline = "alphabetic";
  const word = "mazl";
  const wordWidth = ctx.measureText(word).width;
  const metrics = ctx.measureText(".");
  const advance = wordWidth + metrics.width;
  const ascent = metrics.fontBoundingBoxAscent;
  const descent = metrics.fontBoundingBoxDescent;
  // With line-height 1 the line box is one em tall, the content area centred in it.
  const boxTop = (SAMPLE_HEIGHT - FONT_SIZE) / 2;
  const baseline = boxTop + (FONT_SIZE - (ascent + descent)) / 2 + ascent;
  const left = (SAMPLE_WIDTH - advance) / 2;
  ctx.fillStyle = "#ffffff";
  ctx.fillText(word, left, baseline);
  ctx.fillStyle = "#ff0000";
  ctx.fillText(".", left + wordWidth, baseline);

  const { data } = ctx.getImageData(0, 0, SAMPLE_WIDTH, SAMPLE_HEIGHT);
  const letters: number[] = [];
  const dot: number[] = [];
  for (let y = 0; y < SAMPLE_HEIGHT; y += 2) {
    for (let x = 0; x < SAMPLE_WIDTH; x += 2) {
      const i = (y * SAMPLE_WIDTH + x) * 4;
      if ((data[i + 3] ?? 0) < 140) continue;
      ((data[i + 1] ?? 0) < 100 ? dot : letters).push((x - left) / advance, (y - boxTop) / FONT_SIZE);
    }
  }
  return { letters: new Float32Array(letters), dot: new Float32Array(dot), aspect: FONT_SIZE / advance };
}

function buildGeometry(sampled: Sampled, count: number): BufferGeometry {
  const random = seeded(5782);
  const target = new Float32Array(count * 3);
  const start = new Float32Array(count * 3);
  const seed = new Float32Array(count * 4);
  const lettersCount = sampled.letters.length / 2;
  const dotCount = sampled.dot.length / 2;
  const dotShare = dotCount / Math.max(1, lettersCount + dotCount);
  for (let i = 0; i < count; i++) {
    const isDot = dotCount > 0 && random() < Math.max(dotShare * 1.6, 0.05);
    const source = isDot ? sampled.dot : sampled.letters;
    const pick = Math.floor(random() * (source.length / 2)) * 2;
    target.set([(source[pick] ?? 0) + (random() - 0.5) * 0.002, (source[pick + 1] ?? 0) + (random() - 0.5) * 0.004, (random() - 0.5) * 0.02], i * 3);
    start.set([gaussian(random) * 3.2, gaussian(random) * 1.8, gaussian(random) * 2.2 - 0.5], i * 3);
    // w: size jitter in [0,1), +2 marks the tekhelet dot.
    seed.set([random(), random(), random(), random() + (isDot ? 2 : 0)], i * 4);
  }
  const geometry = new BufferGeometry();
  geometry.setAttribute("position", new BufferAttribute(target, 3));
  geometry.setAttribute("aStart", new BufferAttribute(start, 3));
  geometry.setAttribute("aSeed", new BufferAttribute(seed, 4));
  return geometry;
}

// Closing scene: scattered stars gather, as you scroll, into the wordmark.
export function createOutroScene(options: OutroOptions): OutroScene | null {
  const host = options.canvas.parentElement;
  if (host === null) return null;
  const scene = new Scene();
  const camera = new PerspectiveCamera(FOV, 1, 0.1, 60);
  camera.position.set(0, 0, DISTANCE);
  const uniforms = {
    uTime: { value: 0 }, uProgress: { value: 0 }, uPixel: { value: 1 }, uFade: { value: 1 },
    uCenter: { value: new Vector2(0, 0) }, uWidth: { value: 4 }, uAspect: { value: 0.3 },
  };
  const material = new ShaderMaterial({ vertexShader: vertex, fragmentShader: fragment, uniforms, transparent: true, depthWrite: false, blending: AdditiveBlending });
  let geometry: BufferGeometry | null = null;

  // Lands the word where the HTML wordmark sits, at its size, in world units.
  const place = (width: number, height: number): void => {
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
    const unitsPerPixel = (2 * DISTANCE * Math.tan((FOV * Math.PI) / 360)) / height;
    const box = options.target.getBoundingClientRect();
    const frame = options.canvas.getBoundingClientRect();
    const cx = box.left + box.width / 2 - frame.left - frame.width / 2;
    const cy = box.top + box.height / 2 - frame.top - frame.height / 2;
    uniforms.uCenter.value.set(cx * unitsPerPixel, -cy * unitsPerPixel);
    uniforms.uWidth.value = box.width * unitsPerPixel;
  };


  const player = createPlayer({
    canvas: options.canvas,
    host,
    maxPixelRatio: options.lightweight ? 1.75 : 2,
    transparent: true,
    onResize: place,
    onFrame: (renderer, seconds) => {
      uniforms.uTime.value = options.animate ? seconds : 2;
      const progress = options.animate ? options.progress() : 1;
      uniforms.uProgress.value = progress;
      // The particles step aside once the crisp wordmark has taken over.
      uniforms.uFade.value = 1 - Math.min(1, Math.max(0, (progress - 0.84) / 0.1));
      uniforms.uPixel.value = renderer.getPixelRatio();
      renderer.render(scene, camera);
    },
  }, options.animate);
  if (player === null) {
    material.dispose();
    return null;
  }

  void sampleWordmark().then((sampled) => {
    if (sampled.letters.length === 0) return;
    uniforms.uAspect.value = sampled.aspect;
    geometry = buildGeometry(sampled, options.lightweight ? 7000 : 16000);
    const points = new Points(geometry, material);
    points.frustumCulled = false;
    scene.add(points);
    if (!options.animate) player.renderStill(2);
  });

  return {
    dispose: () => {
      player.dispose();
      geometry?.dispose();
      material.dispose();
    },
  };
}
