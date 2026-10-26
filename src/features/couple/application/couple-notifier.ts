import { sendToUser } from "../../../shared/realtime/connections";
import type { PushTransport } from "../../push/application/ports";
import { memberPushTransport } from "../../push/member-push";
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

export interface CouplePushes {
  pushCoupleRequest(request: CoupleRequestView): void;
  pushCoupleAccepted(requesterId: number, accepterDisplayName: string): void;
}

// No-op when pushes are not configured. The title never carries a name.
export function createCouplePushes(transport: PushTransport): CouplePushes {
  function pushToUser(userId: number, title: string, message: string, type: string): void {
    if (!transport.isEnabled()) return;
    transport
      .send({ recipientId: userId, title, message, data: { type } })
      .then((result) => {
        if (!result.ok) console.error(`Couple push (${type}) not sent: ${result.reason}`);
      })
      .catch(() => console.error(`Couple push (${type}) failed`));
  }

  return {
    pushCoupleRequest(request) {
      const name = firstName(request.requester_name);
      pushToUser(
        request.target_id,
        "Nouvelle demande de couple",
        name ? `${name} souhaite activer le mode couple avec vous` : "Quelqu'un souhaite activer le mode couple avec vous",
        "couple_request",
      );
    },
    pushCoupleAccepted(requesterId, accepterDisplayName) {
      const name = firstName(accepterDisplayName);
      pushToUser(
        requesterId,
        "Demande de couple acceptée",
        name ? `${name} a accepté votre demande de couple` : "Votre demande de couple a été acceptée",
        "couple_accepted",
      );
    },
  };
}

const couplePushes = createCouplePushes(memberPushTransport);
export const pushCoupleRequest = couplePushes.pushCoupleRequest;
export const pushCoupleAccepted = couplePushes.pushCoupleAccepted;
