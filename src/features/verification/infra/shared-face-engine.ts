import { OnnxFaceEngine } from "./onnx-face-engine";

// One engine per models directory for the whole process: the ONNX sessions
// are loaded once, whoever asks first (routes, photo checker, level 2).
const engines = new Map<string, OnnxFaceEngine>();

export function sharedFaceEngine(modelsDir: string): OnnxFaceEngine {
  let engine = engines.get(modelsDir);
  if (!engine) {
    engine = new OnnxFaceEngine(modelsDir);
    engines.set(modelsDir, engine);
  }
  return engine;
}
