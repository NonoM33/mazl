// Ports of the push feature. The notifier depends on these interfaces only; the
// gorush, Postgres and WebSocket adapters live in ../infra and in shared/.

// What the app routes on, and nothing else (V1-CONTRAT section 1).
export type PushData = Readonly<Record<string, string | number>>;

export interface PushMessage {
  readonly recipientId: number;
  readonly title: string;
  readonly message: string;
  readonly data: PushData;
  // Pushes with the same id replace each other on the device.
  readonly collapseId?: string;
}

export type PushResult = { readonly ok: true } | { readonly ok: false; readonly reason: string };

export interface PushTransport {
  // False when the provider has no key: nothing is looked up, nothing is sent.
  isEnabled(): boolean;
  send(message: PushMessage): Promise<PushResult>;
}

export interface PushAudience {
  // False when either member is banned, suspended, restricted or inactive, or
  // when one blocked the other.
  readonly deliverable: boolean;
  // Display name of the actor (the sender, the other half of the match).
  readonly actorName: string | null;
}

export interface PushDirectory {
  audience(recipientId: number, actorId: number): Promise<PushAudience>;
  // The members of the list who may be told something that comes from nobody
  // (an event, the end of their Boost): active, without any active sanction.
  reachable(recipientIds: readonly number[]): Promise<number[]>;
}

export interface ConnectionRegistry {
  // A WebSocket of this member is open: they see the message live.
  isConnected(userId: number): boolean;
}

export interface PushLog {
  error(line: string): void;
}

// The APNs environment a device declared: a TestFlight or App Store build is
// "production", a build installed from Xcode is "sandbox".
export type ApnsEnvironment = "production" | "sandbox";

export interface PushDevice {
  readonly id: number;
  readonly token: string;
  readonly environment: ApnsEnvironment;
}

// The devices of each member, as the app declares them (PUT /api/push/devices).
export interface PushDeviceStore {
  // A token belongs to one member: declared by another, it moves to them.
  register(userId: number, token: string, environment: ApnsEnvironment): Promise<void>;
  // Only the caller's own token; nothing when it is not theirs.
  unregister(userId: number, token: string): Promise<void>;
  devicesOf(userId: number): Promise<PushDevice[]>;
  // Tokens APNs refused for good.
  forget(deviceIds: readonly number[]): Promise<void>;
}
