import sharp from "sharp";

// Synthetic portraits: a head-and-shoulders silhouette on a flat tint of the
// charter. No real person appears in the test data or the screenshots.

const BACKGROUNDS = ["#E7E4DF", "#E1E5EA", "#E8E2E5", "#E1E8E4", "#E3E1EA", "#D9DEE8", "#E6DCCF", "#DCE6E0"];
const FIGURES = ["#2A2D3A", "#4A3F3A", "#3B4A5A", "#5A4A3F", "#30343F", "#6B5446", "#3F4A42", "#463B52"];
const ACCENTS = ["#2747F5", "#B45309", "#15803D", "#7C3AED", "#0E7490", "#BE185D"];

export async function portrait(seed: number, variant = 0): Promise<Buffer> {
  const bg = BACKGROUNDS[(seed + variant) % BACKGROUNDS.length];
  const figure = FIGURES[seed % FIGURES.length];
  const accent = ACCENTS[(seed + variant * 2) % ACCENTS.length];
  const tilt = (variant % 3) * 18 - 18;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="900" height="1200" viewBox="0 0 900 1200">
    <rect width="900" height="1200" fill="${bg}"/>
    <circle cx="${720 - variant * 90}" cy="${240 + variant * 40}" r="${120 + (seed % 3) * 30}" fill="${accent}" opacity="0.18"/>
    <g transform="translate(${450 + tilt} 0)">
      <ellipse cx="0" cy="560" rx="150" ry="180" fill="${figure}"/>
      <path d="M-330 1200 C -320 900, -180 800, 0 800 C 180 800, 320 900, 330 1200 Z" fill="${figure}"/>
    </g>
  </svg>`;
  return sharp(Buffer.from(svg)).jpeg({ quality: 86 }).toBuffer();
}
