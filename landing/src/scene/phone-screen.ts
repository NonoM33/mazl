// The phone's screen is drawn once with the 2D API: an abstract profile, with
// the "Vérifié" badge. Shapes only, no invented person or figure.

const WIDTH = 540;
const HEIGHT = 1110;

function roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number): void {
  ctx.beginPath();
  ctx.roundRect(x, y, w, h, r);
}

export function drawPhoneScreen(): HTMLCanvasElement {
  const canvas = document.createElement("canvas");
  canvas.width = WIDTH;
  canvas.height = HEIGHT;
  const ctx = canvas.getContext("2d");
  if (ctx === null) return canvas;

  ctx.fillStyle = "#ffffff";
  roundRect(ctx, 0, 0, WIDTH, HEIGHT, 64);
  ctx.fill();
  ctx.save();
  roundRect(ctx, 0, 0, WIDTH, HEIGHT, 64);
  ctx.clip();

  // Photo card
  ctx.fillStyle = "#e7e4df";
  roundRect(ctx, 28, 96, WIDTH - 56, 640, 44);
  ctx.fill();
  ctx.fillStyle = "#d6d1c9";
  ctx.beginPath();
  ctx.arc(WIDTH / 2, 340, 92, 0, Math.PI * 2);
  ctx.fill();
  ctx.beginPath();
  ctx.ellipse(WIDTH / 2, 640, 190, 170, 0, Math.PI, 0);
  ctx.fill();

  // "Vérifié" badge
  ctx.fillStyle = "#2747f5";
  roundRect(ctx, 52, 650, 188, 56, 28);
  ctx.fill();
  ctx.strokeStyle = "#ffffff";
  ctx.lineWidth = 6;
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  ctx.beginPath();
  ctx.moveTo(78, 679);
  ctx.lineTo(90, 691);
  ctx.lineTo(112, 666);
  ctx.stroke();
  ctx.fillStyle = "#ffffff";
  ctx.font = '600 26px "Geist", system-ui, sans-serif';
  ctx.textBaseline = "middle";
  ctx.fillText("Vérifié", 128, 680);

  // Name and details as bars
  ctx.fillStyle = "#0b0b0f";
  roundRect(ctx, 40, 770, 250, 30, 15);
  ctx.fill();
  ctx.fillStyle = "#e2e2e6";
  roundRect(ctx, 40, 820, 400, 18, 9);
  ctx.fill();
  ctx.fillStyle = "#f3f3f5";
  for (const [x, w] of [[40, 110], [162, 150], [324, 120]] as const) {
    roundRect(ctx, x, 862, w, 42, 21);
    ctx.fill();
  }

  // Actions
  ctx.strokeStyle = "#e2e2e6";
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.arc(190, 992, 46, 0, Math.PI * 2);
  ctx.stroke();
  ctx.fillStyle = "#2747f5";
  ctx.beginPath();
  ctx.arc(350, 992, 46, 0, Math.PI * 2);
  ctx.fill();

  // Dynamic island
  ctx.fillStyle = "#0b0b0f";
  roundRect(ctx, WIDTH / 2 - 62, 30, 124, 36, 18);
  ctx.fill();
  ctx.restore();
  return canvas;
}
