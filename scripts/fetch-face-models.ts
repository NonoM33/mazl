// Downloads the face models used by the verification feature and checks their
// SHA-256 against the values pinned here. Run: bun run models:fetch
//
//  - YuNet 2023mar (face detection, MIT)       — OpenCV Zoo
//  - SFace 2021dec (face recognition, Apache 2) — OpenCV Zoo
// Never replace them with InsightFace/ArcFace weights: non-commercial licence.
import { mkdir } from "node:fs/promises";
import { join } from "node:path";

interface ModelSpec {
  readonly file: string;
  readonly url: string;
  readonly sha256: string;
}

const MODELS: readonly ModelSpec[] = [
  {
    file: "face_detection_yunet_2023mar.onnx",
    url: "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx",
    sha256: "8f2383e4dd3cfbb4553ea8718107fc0423210dc964f9f4280604804ed2552fa4",
  },
  {
    file: "face_recognition_sface_2021dec.onnx",
    url: "https://github.com/opencv/opencv_zoo/raw/main/models/face_recognition_sface/face_recognition_sface_2021dec.onnx",
    sha256: "0ba9fbfa01b5270c96627c4ef784da859931e02f04419c829e83484087c34e79",
  },
];

function sha256(bytes: Uint8Array): string {
  return new Bun.CryptoHasher("sha256").update(bytes).digest("hex");
}

async function fetchModel(dir: string, model: ModelSpec): Promise<void> {
  const target = join(dir, model.file);
  const existing = Bun.file(target);
  if ((await existing.exists()) && sha256(await existing.bytes()) === model.sha256) {
    console.log(`ok       ${model.file}`);
    return;
  }

  const response = await fetch(model.url);
  if (!response.ok) throw new Error(`${model.file}: HTTP ${response.status}`);
  const bytes = new Uint8Array(await response.arrayBuffer());
  const actual = sha256(bytes);
  if (actual !== model.sha256) {
    throw new Error(`${model.file}: checksum mismatch (expected ${model.sha256}, got ${actual})`);
  }
  await Bun.write(target, bytes);
  console.log(`fetched  ${model.file}`);
}

const dir = process.env.FACE_MODELS_DIR || "models";
await mkdir(dir, { recursive: true });
for (const model of MODELS) await fetchModel(dir, model);
