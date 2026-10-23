import { sendToUser } from "../../../shared/realtime/connections";
import { sendPushNotification } from "../../../onesignal";
import type { CoupleRequestView } from "../../../db";
import type { CoupleView } from "../infra/couple-queries";

// Realtime events (WebSocket) and push notifications of the couple flow
// (docs/couple/CONTRAT.md §3). Realtime is only an accelerator: the app
// re-reads the server on its own, so a failed push is logged without any
// personal data and never fails the request that triggered it.

export function emitCoupleRequest(request: CoupleRequestView): void {
  sendToUser(request.target_id, { type: "couple:request", payload: { request } });
}

export function emitCoupleAccepted(requesterId: number, couple: CoupleView): void {
  sendToUser(requesterId, { type: "couple:accepted", payload: { couple } });
}

export function emitCoupleRejected(requesterId: number, requestId: number): void {
  sendToUser(requesterId, { type: "couple:rejected", payload: { request_id: requestId } });
}

export function emitCoupleEnded(otherMemberId: number, coupleId: number): void {
  sendToUser(otherMemberId, { type: "couple:ended", payload: { couple_id: coupleId } });
}

function firstName(displayName: string | null): string {
  return (displayName ?? "").trim().split(/\s+/)[0] ?? "";
}

// No-op when OneSignal is not configured. The title never carries a name.
function pushToUser(userId: number, title: string, message: string, type: string): void {
  if (!process.env.ONESIGNAL_REST_API_KEY) return;
  sendPushNotification({ userIds: [String(userId)], title, message, data: { type } })
    .then((result) => {
      if (!result.success) console.error(`Couple push (${type}) not sent: ${result.error ?? "unknown"}`);
    })
    .catch(() => console.error(`Couple push (${type}) failed`));
}

export function pushCoupleRequest(request: CoupleRequestView): void {
  const name = firstName(request.requester_name);
  pushToUser(
    request.target_id,
    "Nouvelle demande de couple",
    name ? `${name} souhaite activer le mode couple avec vous` : "Quelqu'un souhaite activer le mode couple avec vous",
    "couple:request",
  );
}

export function pushCoupleAccepted(requesterId: number, accepterDisplayName: string): void {
  const name = firstName(accepterDisplayName);
  pushToUser(
    requesterId,
    "Demande de couple acceptée",
    name ? `${name} a accepté votre demande de couple` : "Votre demande de couple a été acceptée",
    "couple:accepted",
  );
}
