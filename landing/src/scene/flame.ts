import {
  AdditiveBlending, CylinderGeometry, Group, Mesh, MeshBasicMaterial, PerspectiveCamera, PlaneGeometry, Scene, ShaderMaterial, Vector3,
} from "three";
import { flameFragment, glowFragment, quadVertex, waxFragment, waxVertex } from "./flame-shaders";
import { createPlayer } from "./player";

export interface FlameScene {
  readonly dispose: () => void;
}

export interface FlameOptions {
  readonly canvas: HTMLCanvasElement;
  readonly animate: boolean;
  readonly lightweight: boolean;
}

const STILL_TIME = 4.3;
const CANDLE_TOP = 0;
const CANDLE_RADIUS = 0.15;
const CANDLE_HEIGHT = 9;
const WICK_HEIGHT = 0.09;
const FLAME_WIDTH = 0.3;
const FLAME_HEIGHT = 0.8;
const BASES = [-0.62, 0.62] as const;

interface Candle {
  readonly flame: Mesh;
  readonly seed: number;
}

function additive(fragmentShader: string, uniforms: Record<string, { value: number }>, depthTest = true): ShaderMaterial {
  return new ShaderMaterial({
    vertexShader: quadVertex, fragmentShader, uniforms, transparent: true, depthWrite: false, depthTest, blending: AdditiveBlending,
  });
}

// Two chabbat candles: translucent wax, a dark wick, a teardrop flame drawn
// per pixel and its halo. Returns null without WebGL.
export function createFlameScene(options: FlameOptions): FlameScene | null {
  const host = options.canvas.parentElement;
  if (host === null) return null;

  const scene = new Scene();
  const uTime = { value: 0 };
  const owned: { dispose: () => void }[] = [];
  const own = <T extends { dispose: () => void }>(item: T): T => {
    owned.push(item);
    return item;
  };
  const candleGeometry = own(new CylinderGeometry(CANDLE_RADIUS, CANDLE_RADIUS * 1.04, CANDLE_HEIGHT, 48));
  const wickGeometry = own(new CylinderGeometry(0.006, 0.009, WICK_HEIGHT, 8));
  const wickMaterial = own(new MeshBasicMaterial({ color: 0x1a120c }));
  const flameGeometry = own(new PlaneGeometry(FLAME_WIDTH, FLAME_HEIGHT));
  const glowGeometry = own(new PlaneGeometry(1.7, 1.7));
  const haloGeometry = own(new PlaneGeometry(4.2, 4.2));
  const candles: Candle[] = [];

  BASES.forEach((x, index) => {
    const seed = index * 0.37 + 0.11;
    const uSeed = { value: seed };
    const flameCentre = new Vector3(x, CANDLE_TOP + WICK_HEIGHT + FLAME_HEIGHT * 0.3, 0);
    const group = new Group();

    const wax = own(new ShaderMaterial({
      vertexShader: waxVertex, fragmentShader: waxFragment,
      uniforms: { uFlame: { value: flameCentre }, uTop: { value: CANDLE_TOP }, uTime, uSeed },
    }));
    const candle = new Mesh(candleGeometry, wax);
    candle.position.set(x, CANDLE_TOP - CANDLE_HEIGHT / 2, 0);

    const wick = new Mesh(wickGeometry, wickMaterial);
    wick.position.set(x, CANDLE_TOP + WICK_HEIGHT / 2, 0);
    wick.rotation.z = (index === 0 ? 1 : -1) * 0.12;

    const halo = new Mesh(haloGeometry, own(additive(glowFragment, { uTime, uSeed, uStrength: { value: 0.16 } }, false)));
    halo.position.copy(flameCentre);
    const glow = new Mesh(glowGeometry, own(additive(glowFragment, { uTime, uSeed, uStrength: { value: 0.55 } }, false)));
    glow.position.copy(flameCentre);

    const flame = new Mesh(flameGeometry, own(additive(flameFragment, { uTime, uSeed })));
    flame.position.set(x, CANDLE_TOP + WICK_HEIGHT * 0.55 + FLAME_HEIGHT / 2, 0.02);
    halo.renderOrder = 1;
    glow.renderOrder = 2;
    flame.renderOrder = 3;

    group.add(candle, wick, halo, glow, flame);
    scene.add(group);
    candles.push({ flame, seed });
  });

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

  // The flame breathes: a little taller, a little narrower, never in step.
  const breathe = (seconds: number): void => {
    for (const { flame, seed } of candles) {
      const t = seconds + seed * 13;
      const stretch = 1 + Math.sin(t * 2.9) * 0.035 + Math.sin(t * 7.3) * 0.02;
      flame.scale.set(1 / Math.sqrt(stretch), stretch, 1);
    }
  };

  const player = createPlayer({
    canvas: options.canvas,
    host,
    maxPixelRatio: options.lightweight ? 1.75 : 2,
    transparent: false,
    background: 0x0b0b0f,
    onResize: place,
    onFrame: (renderer, seconds) => {
      const time = options.animate ? seconds : STILL_TIME;
      uTime.value = time;
      breathe(time);
      renderer.render(scene, camera);
    },
  }, options.animate);
  if (player === null) {
    for (const item of owned) item.dispose();
    return null;
  }
  if (!options.animate) player.renderStill(STILL_TIME);

  return {
    dispose: () => {
      player.dispose();
      for (const item of owned) item.dispose();
    },
  };
}
