import { open, seal } from "../../../shared/crypto/secret-box";
import type { SecretVault } from "../application/ports";

// Adapter over src/shared/crypto/secret-box.ts (AES-256-GCM, bound context).
export const gcmSecretVault: SecretVault = {
  seal: (plaintext, context) => seal(plaintext, context),
  open: (sealed, context) => open(sealed, context),
};
