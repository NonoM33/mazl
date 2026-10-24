import type { Hono } from "hono";
import type { Sql } from "postgres";
import { generateJWT, verifyAppleIdToken, verifyGoogleIdToken } from "../../auth";
import type { AppVariables } from "../../shared/http/middleware";
import { readConfig, type WebSessionConfig } from "./application/config";
import { PairingService } from "./application/pairing-service";
import { PowService } from "./application/pow-service";
import type { Clock, MemberDirectory, TokenSigner, WebMember } from "./application/ports";
import { SessionService } from "./application/session-service";
import { SocketRegistry, type ClosableSocket } from "./application/socket-registry";
import { PgMemberDirectory } from "./infra/pg-member-directory";
import { PgPairingRepository } from "./infra/pg-pairing-repository";
import { PgSessionRepository } from "./infra/pg-session-repository";
import { createBridge } from "./presentation/bridge";
import { registerAuthRoutes } from "./presentation/auth.routes";
import { registerPairingRoutes } from "./presentation/pairing.routes";
import { registerSessionRoutes } from "./presentation/sessions.routes";

export interface ProviderIdentity {
  readonly sub: string;
}

// The two providers behind a sign-in; replaceable so tests never call out.
export interface IdentityVerifiers {
  google(idToken: string): Promise<ProviderIdentity | null>;
  apple(identityToken: string, audience: string): Promise<ProviderIdentity | null>;
}

export interface WebSessionOptions {
  readonly sql: Sql;
  readonly env?: Readonly<Record<string, string | undefined>>;
  readonly now?: Clock;
  readonly identity?: IdentityVerifiers;
  readonly members?: MemberDirectory;
}

export interface WebSessionModule {
  readonly config: WebSessionConfig;
  readonly pow: PowService;
  readonly pairings: PairingService;
  readonly sessions: SessionService;
  readonly sockets: SocketRegistry;
  readonly members: MemberDirectory;
  readonly identity: IdentityVerifiers;
  readonly now: Clock;
  bridge(req: Request): Promise<void>;
  // Id of the web session a socket ticket belongs to, if the token is one.
  socketSession(token: string): string | undefined;
  socketOpened(sessionId: string, socket: ClosableSocket): void;
  socketClosed(sessionId: string, socket: ClosableSocket): void;
}

const signWithServerKey: TokenSigner = (member: WebMember, ttlSeconds: number) =>
  generateJWT(
    { id: member.id, email: member.email, name: member.name ?? undefined, provider: member.provider, providerId: member.providerId },
    ttlSeconds,
  );

const defaultIdentity: IdentityVerifiers = {
  google: (idToken) => verifyGoogleIdToken(idToken),
  apple: (identityToken, audience) => verifyAppleIdToken(identityToken, audience),
};

export function createWebSessionModule(options: WebSessionOptions): WebSessionModule {
  const config = readConfig(options.env ?? process.env);
  const now = options.now ?? (() => new Date());
  const sockets = new SocketRegistry(signWithServerKey, now);
  const sessions = new SessionService(new PgSessionRepository(options.sql), sockets, now);
  const members = options.members ?? new PgMemberDirectory(options.sql);
  const pairings = new PairingService(
    new PgPairingRepository(options.sql),
    members,
    (member, method, label) => sessions.open(member, method, label),
    now,
  );
  return {
    config,
    pow: new PowService(config.powDifficulty, now),
    pairings,
    sessions,
    sockets,
    members,
    identity: options.identity ?? defaultIdentity,
    now,
    bridge: createBridge({ sessions, config, sign: signWithServerKey }),
    socketSession: (token) => sockets.sessionOf(token),
    socketOpened: (sessionId, socket) => sockets.opened(sessionId, socket),
    socketClosed: (sessionId, socket) => sockets.closed(sessionId, socket),
  };
}

export function registerWebSession(app: Hono<{ Variables: AppVariables }>, module: WebSessionModule): void {
  registerAuthRoutes(app, module);
  registerPairingRoutes(app, module);
  registerSessionRoutes(app, module);
}
