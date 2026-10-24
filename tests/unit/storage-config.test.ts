import { describe, expect, test } from "bun:test";
import { readStorageConfig, StorageConfigError } from "../../src/shared/storage/storage-config";

const COMPLETE = {
  S3_ENDPOINT: "https://s3.mazl.example.com",
  S3_BUCKET: "mazl-uploads",
  S3_ACCESS_KEY_ID: "AKIAEXAMPLE",
  S3_SECRET_ACCESS_KEY: "secret-example-value",
};

describe("readStorageConfig", () => {
  test("nothing set: disk, under UPLOADS_DIR or the default", () => {
    expect(readStorageConfig({})).toEqual({ kind: "disk", uploadsDir: "uploads" });
    expect(readStorageConfig({ UPLOADS_DIR: "/data/uploads" })).toEqual({ kind: "disk", uploadsDir: "/data/uploads" });
  });

  test("blank values count as not set", () => {
    expect(readStorageConfig({ S3_ENDPOINT: "  ", S3_BUCKET: "", UPLOADS_DIR: "" })).toEqual({
      kind: "disk",
      uploadsDir: "uploads",
    });
  });

  test("complete: S3 with the defaults region us-east-1 and path-style addressing", () => {
    expect(readStorageConfig({ ...COMPLETE, UPLOADS_DIR: "/legacy" })).toEqual({
      kind: "s3",
      uploadsDir: "/legacy",
      s3: {
        endpoint: "https://s3.mazl.example.com",
        bucket: "mazl-uploads",
        accessKeyId: "AKIAEXAMPLE",
        secretAccessKey: "secret-example-value",
        region: "us-east-1",
        forcePathStyle: true,
      },
    });
  });

  test("region and path-style can be overridden", () => {
    const config = readStorageConfig({ ...COMPLETE, S3_REGION: "eu-west-3", S3_FORCE_PATH_STYLE: "false" });
    if (config.kind !== "s3") throw new Error("expected s3");
    expect(config.s3.region).toBe("eu-west-3");
    expect(config.s3.forcePathStyle).toBe(false);
    for (const [raw, expected] of [["true", true], ["1", true], ["0", false], ["FALSE", false]] as const) {
      const parsed = readStorageConfig({ ...COMPLETE, S3_FORCE_PATH_STYLE: raw });
      if (parsed.kind !== "s3") throw new Error("expected s3");
      expect(parsed.s3.forcePathStyle).toBe(expected);
    }
  });

  test("each missing required variable makes a partial config, and the error names what is missing", () => {
    for (const missing of ["S3_ENDPOINT", "S3_BUCKET", "S3_ACCESS_KEY_ID", "S3_SECRET_ACCESS_KEY"] as const) {
      const env: Record<string, string | undefined> = { ...COMPLETE };
      delete env[missing];
      expect(() => readStorageConfig(env)).toThrow(StorageConfigError);
      expect(() => readStorageConfig(env)).toThrow(missing);
    }
  });

  test("a lone optional S3 variable is also a half-done setup and refuses to start", () => {
    expect(() => readStorageConfig({ S3_REGION: "eu-west-3" })).toThrow(StorageConfigError);
    expect(() => readStorageConfig({ S3_FORCE_PATH_STYLE: "true" })).toThrow(StorageConfigError);
  });

  test("the error never contains a secret value", () => {
    const env = { ...COMPLETE, S3_BUCKET: "" };
    try {
      readStorageConfig(env);
      throw new Error("should have thrown");
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "";
      expect(message).not.toContain(COMPLETE.S3_SECRET_ACCESS_KEY);
      expect(message).not.toContain(COMPLETE.S3_ACCESS_KEY_ID);
    }
  });

  test("an endpoint that is not an http(s) URL is refused", () => {
    for (const endpoint of ["s3.mazl.example.com", "ftp://x.example.com", "not a url"]) {
      expect(() => readStorageConfig({ ...COMPLETE, S3_ENDPOINT: endpoint })).toThrow(StorageConfigError);
    }
  });

  test("an unreadable S3_FORCE_PATH_STYLE is refused rather than guessed", () => {
    expect(() => readStorageConfig({ ...COMPLETE, S3_FORCE_PATH_STYLE: "maybe" })).toThrow(StorageConfigError);
  });
});
