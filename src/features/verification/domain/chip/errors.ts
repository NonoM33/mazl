// Typed errors of the chip pipeline. Messages describe the structural problem
// only: they never carry chip content (names, document numbers, images).

export class ChipParseError extends Error {
  constructor(reason: string) {
    super(reason);
    this.name = "ChipParseError";
  }
}

export class TlvError extends ChipParseError {
  constructor(reason: string) {
    super(`tlv: ${reason}`);
    this.name = "TlvError";
  }
}

// A signature algorithm or curve we deliberately do not implement.
export class UnsupportedAlgorithmError extends ChipParseError {
  constructor(what: string) {
    super(`unsupported algorithm: ${what}`);
    this.name = "UnsupportedAlgorithmError";
  }
}

// An elliptic-curve parameter set or point that fails validation.
export class InvalidKeyError extends ChipParseError {
  constructor(reason: string) {
    super(`invalid key: ${reason}`);
    this.name = "InvalidKeyError";
  }
}
