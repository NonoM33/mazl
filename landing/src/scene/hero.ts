import { AdditiveBlending, BufferAttribute, BufferGeometry, PerspectiveCamera, Points, Scene, ShaderMaterial, Vector3 } from "three";
import { heroFragment, heroVertex } from "./hero-shaders";
import { createPlayer, type Player } from "./player";
import { gaussian, seeded } from "./random";

export interface HeroScene {
  readonly dispose: () => void;
}

export interface HeroOptions {
  readonly canvas: HTMLCanvasElement;
  readonly animate: boolean;
  readonly lightweight: boolean;
  // Scroll progress of the hero, 0 to 1.
  readonly progress: () => number;
}

const STILL_PROGRESS = 0.9;
const FOV = 45;
const DISTANCE = 9;

function buildGeometry(count: number): BufferGeometry {
  const random = seeded(20261024);
  const cloud = new Float32Array(count * 3);
  const jitter = new Float32Array(count * 3);
  const seed = new Float32Array(count * 4);
  for (let i = 0; i < count; i++) {
    const strand = i % 2;
    cloud.set([gaussian(random), gaussian(random), gaussian(random)], i * 3);
    jitter.set([gaussian(random), gaussian(random), gaussian(random)], i * 3);
    seed.set([random(), random(), random(), strand], i * 4);
  }
  const geometry = new BufferGeometry();
  geometry.setAttribute("position", new BufferAttribute(cloud, 3));
  geometry.setAttribute("aJit", new BufferAttribute(jitter, 3));
  geometry.setAttribute("aSeed", new BufferAttribute(seed, 4));
  return geometry;
}

// "Le fil de tekhelet" : the hero scene. Returns null without WebGL.
export function createHeroScene(options: HeroOptions): HeroScene | null {
  const host = options.canvas.parentElement;
  if (host === null) return null;
  const count = options.lightweight ? 3600 : window.innerWidth > 1800 ? 12000 : 8500;
  const geometry = buildGeometry(count);
  const uTime = { value: 0 };
  const uProgress = { value: options.animate ? 0 : STILL_PROGRESS };
  const uPixel = { value: 1 };
  const uHalf = { value: 6 };
  const uSpan = { value: 5.7 };
  const uTilt = { value: 0 };
  const uMouse = { value: new Vector3(99, 99, 0) };
  const material = new ShaderMaterial({
    vertexShader: heroVertex,
    fragmentShader: heroFragment,
    transparent: true,
    depthWrite: false,
    blending: AdditiveBlending,
    uniforms: { uTime, uProgress, uPixel, uHalf, uSpan, uTilt, uMouse },
  });
  const points = new Points(geometry, material);
  points.frustumCulled = false;
  const scene = new Scene();
  scene.add(points);
  const camera = new PerspectiveCamera(FOV, 1, 0.1, 60);
  camera.position.set(0, 0, DISTANCE);

  const halfHeight = DISTANCE * Math.tan((FOV / 2) * (Math.PI / 180));
  const pointer = { x: 0, y: 0, targetX: 0, targetY: 0 };
  let shown = options.animate ? 0 : STILL_PROGRESS;
  let player: Player | null = null;

  const onPointer = (event: PointerEvent): void => {
    pointer.targetX = (event.clientX / window.innerWidth) * 2 - 1;
    pointer.targetY = -((event.clientY / window.innerHeight) * 2 - 1);
  };
  const reset = (): void => {
    pointer.targetX = 0;
    pointer.targetY = 0;
  };
  if (options.animate && window.matchMedia("(pointer: fine)").matches) {
    window.addEventListener("pointermove", onPointer, { passive: true });
    document.addEventListener("pointerleave", reset);
  }

  player = createPlayer({
    canvas: options.canvas,
    host,
    maxPixelRatio: options.lightweight ? 1.75 : 2,
    transparent: true,
    onResize: (width, height) => {
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
      uHalf.value = halfHeight * camera.aspect;
      const portrait = camera.aspect < 1;
      uSpan.value = portrait ? halfHeight * 0.8 : uHalf.value * 0.96;
      uTilt.value = portrait ? Math.PI / 2 - 0.3 : 0;
    },
    onFrame: (renderer, seconds, delta) => {
      const target = options.animate ? options.progress() : STILL_PROGRESS;
      shown += (target - shown) * Math.min(1, delta * 7);
      pointer.x += (pointer.targetX - pointer.x) * Math.min(1, delta * 3);
      pointer.y += (pointer.targetY - pointer.y) * Math.min(1, delta * 3);
      const aspect = camera.aspect;
      uMouse.value.set(pointer.x * halfHeight * aspect, pointer.y * halfHeight, 0);
      camera.position.set(pointer.x * 0.35, pointer.y * 0.2, DISTANCE);
      camera.lookAt(0, 0, 0);
      uTime.value = options.animate ? seconds : 2.4;
      uProgress.value = shown;
      uPixel.value = player?.pixelRatio() ?? 1;
      renderer.render(scene, camera);
    },
  }, options.animate);
  if (player === null) {
    geometry.dispose();
    material.dispose();
    window.removeEventListener("pointermove", onPointer);
    document.removeEventListener("pointerleave", reset);
    return null;
  }
  if (!options.animate) player.renderStill(2.4);

  return {
    dispose: () => {
      window.removeEventListener("pointermove", onPointer);
      document.removeEventListener("pointerleave", reset);
      player?.dispose();
      geometry.dispose();
      material.dispose();
    },
  };
}
