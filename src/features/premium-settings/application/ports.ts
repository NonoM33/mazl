import type { Passport, StoredSettings } from "../domain/settings";

export interface SettingsStore {
  read(userId: number): Promise<StoredSettings>;
  setPassport(userId: number, passport: Passport | null): Promise<void>;
  setIncognito(userId: number, enabled: boolean): Promise<void>;
  setReadReceipts(userId: number, enabled: boolean): Promise<void>;
}

export interface PlusLookup {
  isPlus(userId: number): Promise<boolean>;
}
