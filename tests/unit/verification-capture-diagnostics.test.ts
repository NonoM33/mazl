import { expect, test } from "bun:test";
import { captureDiagnosticsLine, captureDiagnosticsSchema } from "../../src/features/verification/presentation/capture-diagnostics";

const sample = {
  platform: "ios",
  frames: 120,
  framesWithFace: 118,
  feedback: { offCenter: 118, noFace: 2 },
  imageWidth: 1920,
  imageHeight: 1080,
  sensorOrientation: 90,
  rotation: 90,
  lastFace: { cx: 0.89, cy: 0.28, w: 0.4, frameWidth: 1080, frameHeight: 1920 },
};

test("the diagnostics of a selfie that did not complete read as one line of counts", () => {
  const parsed = captureDiagnosticsSchema.parse(sample);
  expect(captureDiagnosticsLine(44, parsed)).toBe(
    "Selfie diagnostics user 44 (ios): 120 frame(s), 118 with a face | offCenter=118 noFace=2 | image 1920x1080 sensor 90 rotation 90 | last face cx=0.89 cy=0.28 w=0.40 in 1080x1920",
  );
});

test("nothing but counts is accepted", () => {
  expect(captureDiagnosticsSchema.safeParse({ ...sample, image: "base64…" }).success).toBe(false);
  expect(captureDiagnosticsSchema.safeParse({ ...sample, feedback: { "<script>": 1 } }).success).toBe(false);
});
