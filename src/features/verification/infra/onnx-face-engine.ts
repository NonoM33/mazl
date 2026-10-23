import { join } from "node:path";
import * as ort from "onnxruntime-node";
import type { FaceEngine, RgbImage } from "../application/ports";
import type { DetectedFace, Embedding } from "../domain/types";
import { resizeBilinear, warpAffineBilinear } from "./image-ops";
import { ARCFACE_TEMPLATE, estimateSimilarityTransform, type Point2 } from "./similarity-transform";
import { decodeYunet, type YunetOutputs } from "./yunet-decoder";

// Face detection (YuNet 2023mar) and recognition (SFace 2021dec), both from
// the OpenCV Zoo, run with ONNX Runtime. Pre-processing follows OpenCV's
// FaceDetectorYN and FaceRecognizerSF so that the published SFace cosine
// threshold (0.363) applies as is.

export const DETECTOR_FILE = "face_detection_yunet_2023mar.onnx";
export const RECOGNIZER_FILE = "face_recognition_sface_2021dec.onnx";
export const EMBEDDING_MODEL_NAME = "sface_2021dec";

const DETECTION_SCORE_THRESHOLD = 0.7;
const NMS_THRESHOLD = 0.3;
const TOP_K = 5000;
const FALLBACK_DETECTOR_SIZE = 640;
const ALIGNED_SIZE = 112;

export class ModelLoadError extends Error {
  constructor(path: string, cause: unknown) {
    super(`cannot load face model ${path}: ${cause instanceof Error ? cause.message : String(cause)}`);
    this.name = "ModelLoadError";
  }
}

interface LoadedModels {
  readonly detector: ort.InferenceSession;
  readonly recognizer: ort.InferenceSession;
  readonly detectorInput: { readonly width: number; readonly height: number };
}

export class OnnxFaceEngine implements FaceEngine {
  private models: Promise<LoadedModels> | null = null;

  constructor(private readonly modelsDir: string) {}

  // Models are loaded once, on first use, so that booting the server stays
  // cheap and a missing model only breaks verification, not the whole API.
  private load(): Promise<LoadedModels> {
    this.models ??= this.loadModels().catch((error: unknown) => {
      this.models = null;
      throw error;
    });
    return this.models;
  }

  private async loadModels(): Promise<LoadedModels> {
    const open = async (file: string) => {
      const path = join(this.modelsDir, file);
      try {
        return await ort.InferenceSession.create(path, { logSeverityLevel: 3, executionProviders: ["cpu"] });
      } catch (error: unknown) {
        throw new ModelLoadError(path, error);
      }
    };
    const [detector, recognizer] = await Promise.all([open(DETECTOR_FILE), open(RECOGNIZER_FILE)]);
    return { detector, recognizer, detectorInput: detectorInputSize(detector) };
  }

  async detect(image: RgbImage): Promise<readonly DetectedFace[]> {
    const { detector, detectorInput } = await this.load();
    const scale = Math.min(detectorInput.width / image.width, detectorInput.height / image.height);
    const resized = resizeBilinear(
      image,
      Math.max(1, Math.min(detectorInput.width, Math.round(image.width * scale))),
      Math.max(1, Math.min(detectorInput.height, Math.round(image.height * scale))),
    );
    const input = new ort.Tensor("float32", toPaddedBgrPlanes(resized, detectorInput), [
      1,
      3,
      detectorInput.height,
      detectorInput.width,
    ]);
    const outputs = await detector.run({ [detector.inputNames[0] ?? "input"]: input });
    const raw: Record<string, Float32Array> = {};
    for (const [name, tensor] of Object.entries(outputs)) raw[name] = tensor.data as Float32Array;
    const faces = decodeYunet(raw as unknown as YunetOutputs, detectorInput, DETECTION_SCORE_THRESHOLD, NMS_THRESHOLD, TOP_K);
    return faces.map((face) => toImageCoordinates(face, scale));
  }

  async embed(image: RgbImage, face: DetectedFace): Promise<Embedding> {
    const { recognizer } = await this.load();
    const lm = face.landmarks;
    const source: Point2[] = [lm.rightEye, lm.leftEye, lm.nose, lm.rightMouth, lm.leftMouth].map((p) => [p.x, p.y]);
    const transform = estimateSimilarityTransform(source, ARCFACE_TEMPLATE);
    const aligned = warpAffineBilinear(image, transform, ALIGNED_SIZE, ALIGNED_SIZE);
    // blobFromImage(scale 1, mean 0, swapRB) on OpenCV's BGR crop: the network
    // receives RGB planes with raw 0-255 values.
    const input = new ort.Tensor("float32", toRgbPlanes(aligned), [1, 3, ALIGNED_SIZE, ALIGNED_SIZE]);
    const outputs = await recognizer.run({ [recognizer.inputNames[0] ?? "data"]: input });
    const first = outputs[recognizer.outputNames[0] ?? "fc1"];
    if (!first) throw new Error("SFace returned no output");
    return l2Normalize(Float32Array.from(first.data as Float32Array));
  }
}

function detectorInputSize(session: ort.InferenceSession): { width: number; height: number } {
  const meta = session.inputMetadata.find((m) => m.name === session.inputNames[0]);
  const shape = meta && meta.isTensor ? meta.shape : [];
  const height = typeof shape[2] === "number" && shape[2] > 0 ? shape[2] : FALLBACK_DETECTOR_SIZE;
  const width = typeof shape[3] === "number" && shape[3] > 0 ? shape[3] : FALLBACK_DETECTOR_SIZE;
  return { width, height };
}

// YuNet consumes BGR (cv::dnn::blobFromImage without swapRB on a BGR Mat);
// the image sits in the top-left corner and the rest is 0, like
// FaceDetectorYN's padWithDivisor.
function toPaddedBgrPlanes(image: RgbImage, target: { width: number; height: number }): Float32Array {
  const plane = target.width * target.height;
  const out = new Float32Array(3 * plane);
  for (let y = 0; y < image.height; y++) {
    for (let x = 0; x < image.width; x++) {
      const src = (y * image.width + x) * 3;
      const dst = y * target.width + x;
      out[dst] = image.data[src + 2] ?? 0; // B
      out[plane + dst] = image.data[src + 1] ?? 0; // G
      out[2 * plane + dst] = image.data[src] ?? 0; // R
    }
  }
  return out;
}

function toRgbPlanes(image: RgbImage): Float32Array {
  const plane = image.width * image.height;
  const out = new Float32Array(3 * plane);
  for (let i = 0; i < plane; i++) {
    out[i] = image.data[i * 3] ?? 0;
    out[plane + i] = image.data[i * 3 + 1] ?? 0;
    out[2 * plane + i] = image.data[i * 3 + 2] ?? 0;
  }
  return out;
}

function toImageCoordinates(face: DetectedFace, scale: number): DetectedFace {
  const p = (pt: { x: number; y: number }) => ({ x: pt.x / scale, y: pt.y / scale });
  return {
    box: { x: face.box.x / scale, y: face.box.y / scale, width: face.box.width / scale, height: face.box.height / scale },
    score: face.score,
    landmarks: {
      rightEye: p(face.landmarks.rightEye),
      leftEye: p(face.landmarks.leftEye),
      nose: p(face.landmarks.nose),
      rightMouth: p(face.landmarks.rightMouth),
      leftMouth: p(face.landmarks.leftMouth),
    },
  };
}

function l2Normalize(v: Float32Array): Float32Array {
  let sum = 0;
  for (const x of v) sum += x * x;
  const norm = Math.sqrt(sum);
  if (norm === 0) return v;
  return v.map((x) => x / norm);
}
