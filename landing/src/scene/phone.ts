import {
  AmbientLight, CanvasTexture, DirectionalLight, ExtrudeGeometry, Group, Mesh, MeshBasicMaterial, MeshStandardMaterial,
  PerspectiveCamera, PlaneGeometry, PointLight, Scene, Shape, SRGBColorSpace,
} from "three";
import { createPlayer } from "./player";
import { drawPhoneScreen } from "./phone-screen";

export interface PhoneScene {
  readonly dispose: () => void;
}

export interface PhoneOptions {
  readonly canvas: HTMLCanvasElement;
  readonly animate: boolean;
  // Position of the section in the viewport, 0 (entering) to 1 (leaving).
  readonly progress: () => number;
}

const WIDTH = 1;
const HEIGHT = 2.06;
const DEPTH = 0.1;
const RADIUS = 0.17;

function bodyShape(): Shape {
  const x = -WIDTH / 2;
  const y = -HEIGHT / 2;
  const shape = new Shape();
  shape.moveTo(x + RADIUS, y);
  shape.lineTo(x + WIDTH - RADIUS, y);
  shape.quadraticCurveTo(x + WIDTH, y, x + WIDTH, y + RADIUS);
  shape.lineTo(x + WIDTH, y + HEIGHT - RADIUS);
  shape.quadraticCurveTo(x + WIDTH, y + HEIGHT, x + WIDTH - RADIUS, y + HEIGHT);
  shape.lineTo(x + RADIUS, y + HEIGHT);
  shape.quadraticCurveTo(x, y + HEIGHT, x, y + HEIGHT - RADIUS);
  shape.lineTo(x, y + RADIUS);
  shape.quadraticCurveTo(x, y, x + RADIUS, y);
  return shape;
}

// A stylised phone that turns as the "Vérifiés" section crosses the screen.
export function createPhoneScene(options: PhoneOptions): PhoneScene | null {
  const host = options.canvas.parentElement;
  if (host === null) return null;

  const body = new ExtrudeGeometry(bodyShape(), { depth: DEPTH, bevelEnabled: true, bevelThickness: 0.025, bevelSize: 0.025, bevelSegments: 5, curveSegments: 28 });
  body.translate(0, 0, -DEPTH / 2);
  const bodyMaterial = new MeshStandardMaterial({ color: 0x15151b, metalness: 0.85, roughness: 0.32 });
  const texture = new CanvasTexture(drawPhoneScreen());
  texture.colorSpace = SRGBColorSpace;
  texture.anisotropy = 4;
  const screenGeometry = new PlaneGeometry(WIDTH - 0.07, (WIDTH - 0.07) * (1110 / 540));
  const screenMaterial = new MeshBasicMaterial({ map: texture, transparent: true });
  const screen = new Mesh(screenGeometry, screenMaterial);
  screen.position.z = DEPTH / 2 + 0.0265;

  const phone = new Group();
  phone.add(new Mesh(body, bodyMaterial), screen);
  const scene = new Scene();
  scene.add(phone);
  scene.add(new AmbientLight(0xffffff, 1.1));
  const key = new DirectionalLight(0xffffff, 2.6);
  key.position.set(2.5, 3, 4);
  scene.add(key);
  const rim = new PointLight(0x5b78ff, 24, 12, 2);
  rim.position.set(-2.4, -0.6, 1.8);
  scene.add(rim);
  const camera = new PerspectiveCamera(28, 1, 0.1, 30);
  camera.position.set(0, 0, 5.1);

  // Fonts may arrive after the first drawing: redraw the screen when they do.
  void document.fonts.ready.then(() => {
    const redraw = drawPhoneScreen();
    texture.image = redraw;
    texture.needsUpdate = true;
    if (!options.animate) player?.renderStill(0);
  });

  const pose = (progress: number, seconds: number): void => {
    const turn = (progress - 0.5) * 2; // -1 to 1 across the section
    phone.rotation.y = -0.85 + (turn + 1) * 0.85 + (options.animate ? Math.sin(seconds * 0.6) * 0.04 : 0);
    phone.rotation.x = 0.1 - turn * 0.05;
    phone.position.y = options.animate ? Math.sin(seconds * 0.8) * 0.03 : 0;
  };

  let shown = options.animate ? options.progress() : 0.5;
  const player = createPlayer({
    canvas: options.canvas,
    host,
    maxPixelRatio: 2,
    transparent: true,
    onResize: (width, height) => {
      camera.aspect = width / height;
      camera.fov = camera.aspect < 0.8 ? 36 : 30;
      camera.updateProjectionMatrix();
    },
    onFrame: (renderer, seconds, delta) => {
      shown += ((options.animate ? options.progress() : 0.5) - shown) * Math.min(1, delta * 6);
      pose(shown, seconds);
      renderer.render(scene, camera);
    },
  }, options.animate);
  if (player === null) {
    body.dispose();
    bodyMaterial.dispose();
    screenGeometry.dispose();
    screenMaterial.dispose();
    texture.dispose();
    return null;
  }
  if (!options.animate) player.renderStill(0);

  return {
    dispose: () => {
      player.dispose();
      body.dispose();
      bodyMaterial.dispose();
      screenGeometry.dispose();
      screenMaterial.dispose();
      texture.dispose();
    },
  };
}
