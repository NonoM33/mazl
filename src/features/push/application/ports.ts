// Ports of the push feature. The notifier depends on these interfaces only; the
// OneSignal, Postgres and WebSocket adapters live in ../infra and in shared/.

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
}

export interface ConnectionRegistry {
  // A WebSocket of this member is open: they see the message live.
  isConnected(userId: number): boolean;
}

export interface PushLog {
  error(line: string): void;
}
