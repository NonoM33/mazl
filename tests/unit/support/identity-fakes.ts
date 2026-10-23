import type {
  IdentityRecord,
  IdentityRepository,
  IdentitySaveResult,
} from "../../../src/features/verification/application/identity-ports";

// In-memory IdentityRepository implementing only the real port.
export class FakeIdentityRepository implements IdentityRepository {
  readonly owners = new Map<string, number>();
  readonly banned = new Set<string>();
  readonly saved: IdentityRecord[] = [];
  lookups = 0;
  raceLost = false;

  async isBanned(fingerprint: string): Promise<boolean> {
    this.lookups += 1;
    return this.banned.has(fingerprint);
  }
  async ownerOf(fingerprint: string): Promise<number | null> {
    this.lookups += 1;
    return this.owners.get(fingerprint) ?? null;
  }
  async save(record: IdentityRecord): Promise<IdentitySaveResult> {
    if (this.raceLost) return "fingerprint_taken";
    this.saved.push(record);
    this.owners.set(record.fingerprint, record.userId);
    return "saved";
  }
}
