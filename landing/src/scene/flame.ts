import {
  AdditiveBlending, AmbientLight, BufferAttribute, BufferGeometry, CylinderGeometry, Group, Mesh, MeshStandardMaterial,
  PerspectiveCamera, PointLight, Points, Scene, ShaderMaterial, Vector3,
} from "three";
import { createPlayer } from "./player";
import { seeded } from "./random";

export interface FlameScene {
  readonly dispose: () => void;
}

export interface FlameOptions {
  readonly canvas: HTMLCanvasElement;
  readonly animate: boolean;
  readonly lightweight: boolean;
}

const vertex = /* glsl */ `
uniform float uTime;
uniform float uPixel;
uniform vec3 uBase;
attribute vec4 aSeed;
varying float vLife;

void main() {
  float life = fract(uTime * (0.38 + aSeed.x * 0.4) + aSeed.y);
  float width = 0.17 * (1.0 - life) * (0.3 + sin(life * 2.8));
  float angle = aSeed.z * 6.2832;
  vec2 ring = width * sqrt(aSeed.w) * vec2(cos(angle), sin(angle));
  float sway = sin(uTime * 2.1 + aSeed.y * 9.0) * 0.03 * life + sin(uTime * 0.8) * 0.025 * life;
  vec3 pos = uBase + vec3(ring.x + sway, life * 0.78, ring.y);
  vec4 mv = modelViewMatrix * vec4(pos, 1.0);
  gl_PointSize = (1.0 - life * 0.55) * uPixel * (150.0 / -mv.z) * (0.7 + aSeed.x * 0.6);
  gl_Position = projectionMatrix * mv;
  vLife = life;
}
`;

const fragment = /* glsl */ `
varying float vLife;
void main() {
  float d = length(gl_PointCoord - 0.5) * 2.0;
  if (d > 1.0) discard;
  float halo = pow(1.0 - d, 2.0);
  vec3 hot = vec3(1.0, 0.84, 0.46);
  vec3 gold = vec3(0.949, 0.710, 0.267);
  vec3 tip = vec3(0.86, 0.5, 0.12);
  vec3 color = mix(mix(hot, gold, smoothstep(0.0, 0.35, vLife)), tip, smoothstep(0.5, 1.0, vLife));
  float alpha = smoothstep(0.0, 0.07, vLife) * pow(1.0 - vLife, 1.25);
  gl_FragColor = vec4(color, halo * alpha * 0.8);
}
`;

const BLOOM = /* glsl */ `
uniform float uTime;
uniform float uPixel;
attribute vec4 aSeed;
varying float vPulse;
void main() {
  vec4 mv = modelViewMatrix * vec4(position, 1.0);
  vPulse = 0.75 + 0.25 * sin(uTime * 3.1 + aSeed.x * 20.0) * sin(uTime * 1.3 + aSeed.y * 9.0);
  gl_PointSize = uPixel * (1100.0 / -mv.z) * (0.6 + aSeed.x * 0.5);
  gl_Position = projectionMatrix * mv;
}
`;

const BLOOM_FRAGMENT = /* glsl */ `
varying float vPulse;
void main() {
  float d = length(gl_PointCoord - 0.5) * 2.0;
  if (d > 1.0) discard;
  gl_FragColor = vec4(0.949, 0.710, 0.267, pow(1.0 - d, 2.4) * 0.3 * vPulse);
}
`;

// Two chabbat candles whose flames are made of gold light.
export function createFlameScene(options: FlameOptions): FlameScene | null {
  const host = options.canvas.parentElement;
  if (host === null) return null;
  const perFlame = options.lightweight ? 340 : 520;
  const bases = [[-0.62, 0.0], [0.62, 0.0]] as const;
  const candleTop = 0.0;

  const scene = new Scene();
  const candles = new Group();
  const candleGeometry = new CylinderGeometry(0.15, 0.16, 9, 40);
  const candleMaterial = new MeshStandardMaterial({ color: 0xe9e2d0, roughness: 0.78, metalness: 0 });
  const owned: { dispose: () => void }[] = [candleGeometry, candleMaterial];
  const clocks: { value: number }[] = [];
  const pixels: { value: number }[] = [];
  const random = seeded(5785);

  for (const [x] of bases) {
    const candle = new Mesh(candleGeometry, candleMaterial);
    candle.position.set(x, candleTop - 4.5, 0);
    candles.add(candle);

    const seed = new Float32Array(perFlame * 4);
    const origin = new Float32Array(perFlame * 3);
    for (let i = 0; i < perFlame; i++) seed.set([random(), random(), random(), random()], i * 4);
    const geometry = new BufferGeometry();
    geometry.setAttribute("position", new BufferAttribute(origin, 3));
    geometry.setAttribute("aSeed", new BufferAttribute(seed, 4));
    const uTime = { value: 0 };
    const uPixel = { value: 1 };
    clocks.push(uTime);
    pixels.push(uPixel);
    const material = new ShaderMaterial({
      vertexShader: vertex, fragmentShader: fragment, transparent: true, depthWrite: false, blending: AdditiveBlending,
      uniforms: { uTime, uPixel, uBase: { value: new Vector3(x, candleTop + 0.02, 0) } },
    });
    const flame = new Points(geometry, material);
    flame.frustumCulled = false;
    scene.add(flame);

    const bloomPosition = new Float32Array([x, candleTop + 0.32, 0, x, candleTop + 0.22, 0.05]);
    const bloomGeometry = new BufferGeometry();
    bloomGeometry.setAttribute("position", new BufferAttribute(bloomPosition, 3));
    bloomGeometry.setAttribute("aSeed", new BufferAttribute(new Float32Array([random(), random(), 0, 0, random(), random(), 0, 0]), 4));
    const bloomMaterial = new ShaderMaterial({
      vertexShader: BLOOM, fragmentShader: BLOOM_FRAGMENT, transparent: true, depthWrite: false, blending: AdditiveBlending,
      uniforms: { uTime, uPixel },
    });
    const bloom = new Points(bloomGeometry, bloomMaterial);
    bloom.frustumCulled = false;
    scene.add(bloom);

    const light = new PointLight(0xf2b544, 3.2, 6, 2);
    light.position.set(x, candleTop + 0.5, 0.6);
    scene.add(light);
    owned.push(geometry, material, bloomGeometry, bloomMaterial);
  }
  scene.add(candles, new AmbientLight(0xf4f1ea, 0.12));

  const camera = new PerspectiveCamera(30, 1, 0.1, 40);
  const place = (width: number, height: number): void => {
    // Wide screens: the candles sit on the right, the text on the left. Narrow
    // ones (the stylesheet stacks the text under the candles): centred above.
    const stacked = width <= 900;
    const x = stacked ? 0 : -1.1 * (width / height);
    const y = stacked ? -0.9 : -0.35;
    camera.aspect = width / height;
    camera.position.set(x, y, stacked ? 9 : 8.4);
    camera.lookAt(x, y, 0);
    camera.updateProjectionMatrix();
  };

  const player = createPlayer({
    canvas: options.canvas,
    host,
    maxPixelRatio: 2,
    transparent: false,
    background: 0x0b0b0f,
    onResize: place,
    onFrame: (renderer, seconds) => {
      for (const clock of clocks) clock.value = options.animate ? seconds : 4.3;
      for (const pixel of pixels) pixel.value = renderer.getPixelRatio();
      renderer.render(scene, camera);
    },
  }, options.animate);
  if (player === null) {
    for (const item of owned) item.dispose();
    return null;
  }
  if (!options.animate) player.renderStill(4.3);

  return {
    dispose: () => {
      player.dispose();
      for (const item of owned) item.dispose();
    },
  };
}
