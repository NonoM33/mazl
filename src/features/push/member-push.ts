import { sql } from "../../db";
import type { PushDeviceStore, PushTransport } from "./application/ports";
import { createGorushTransport } from "./infra/gorush-transport";
import { PgPushDevices } from "./infra/pg-push-devices";

// The push transport of the whole server: gorush, configured by the environment
// at every call, so a server started without GORUSH_URL or GORUSH_SHARED_SECRET
// sends nothing and asks nothing of the database.
//   GORUSH_URL            http://neo-gorush:8088 (internal Docker network `coolify`)
//   GORUSH_SHARED_SECRET  the secret of the gorush guard
//   APNS_TOPIC            the app's bundle id, com.mazl.app by default

const DEFAULT_TOPIC = "com.mazl.app";

export function gorushTransportFromEnv(devices: PushDeviceStore, env: Readonly<Record<string, string | undefined>> = process.env): PushTransport {
  const current = () =>
    createGorushTransport({
      url: env.GORUSH_URL?.trim() ?? "",
      secret: env.GORUSH_SHARED_SECRET ?? "",
      topic: env.APNS_TOPIC?.trim() || DEFAULT_TOPIC,
      devices,
    });
  return { isEnabled: () => current().isEnabled(), send: (message) => current().send(message) };
}

export const memberPushDevices: PushDeviceStore = new PgPushDevices(sql);
export const memberPushTransport: PushTransport = gorushTransportFromEnv(memberPushDevices);
