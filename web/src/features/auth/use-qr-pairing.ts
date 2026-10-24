import { useCallback, useEffect, useEffectEvent, useRef, useState } from "react";
import { api, request } from "../../shared/api/client";
import { ApiError } from "../../shared/api/errors";
import type { PairingStatus, WebChallenge, WebPairing, WebPairingStatus } from "../../shared/api/types";
import { solve } from "./pow-solver";

// The QR sign-in, like WhatsApp Web (docs/web/adr/W03-connexion-antibot.md):
// solve a proof of work, open a pairing, show `mazl-web:<code>`, then poll
// with the browser secret until the phone approves, refuses or time runs out.

export type QrState =
  | { readonly phase: "preparing" }
  | { readonly phase: "showing"; readonly qr: string; readonly status: Exclude<PairingStatus, "approved"> }
  | { readonly phase: "approved" }
  | { readonly phase: "stalled"; readonly reason: "denied" | "expired" | "error" };

const POLL_MS = 2000;
const MAX_AUTO_RENEW = 4;

export async function proofOfWork(signal?: AbortSignal): Promise<{ challenge: string; nonce: string }> {
  const { challenge, difficulty } = await api.post<WebChallenge>("/api/web/auth/challenge");
  return { challenge, nonce: await solve(challenge, difficulty, signal) };
}

export function useQrPairing(onApproved: () => void): { readonly state: QrState; readonly restart: () => void } {
  const [state, setState] = useState<QrState>({ phase: "preparing" });
  const [round, setRound] = useState(0);
  const renewals = useRef(0);
  const approved = useEffectEvent(() => { onApproved(); });

  useEffect(() => {
    const controller = new AbortController();
    let timer: number | null = null;
    const poll = async (id: string, secret: string, qr: string) => {
      try {
        const result = await request<WebPairingStatus>(`/api/web/auth/qr/${id}`, { headers: { "X-Pairing-Secret": secret }, signal: controller.signal });
        if (controller.signal.aborted) return;
        if (result.status === "approved") { setState({ phase: "approved" }); approved(); return; }
        if (result.status === "denied") { setState({ phase: "stalled", reason: "denied" }); return; }
        if (result.status === "expired") {
          if (renewals.current < MAX_AUTO_RENEW) { renewals.current += 1; setRound((value) => value + 1); }
          else setState({ phase: "stalled", reason: "expired" });
          return;
        }
        setState({ phase: "showing", qr, status: result.status });
        timer = window.setTimeout(() => void poll(id, secret, qr), POLL_MS);
      } catch (error) {
        if (controller.signal.aborted) return;
        if (error instanceof ApiError && error.isRateLimited) timer = window.setTimeout(() => void poll(id, secret, qr), (error.retryAfter ?? 10) * 1000);
        else setState({ phase: "stalled", reason: "error" });
      }
    };
    const start = async () => {
      setState({ phase: "preparing" });
      try {
        const pow = await proofOfWork(controller.signal);
        const { pairing } = await api.post<WebPairing>("/api/web/auth/qr", { pow });
        const qr = `mazl-web:${pairing.code}`;
        setState({ phase: "showing", qr, status: "pending" });
        timer = window.setTimeout(() => void poll(pairing.id, pairing.browser_secret, qr), POLL_MS);
      } catch {
        if (!controller.signal.aborted) setState({ phase: "stalled", reason: "error" });
      }
    };
    void start();
    return () => {
      controller.abort();
      if (timer !== null) window.clearTimeout(timer);
    };
  }, [round]);

  const restart = useCallback(() => {
    renewals.current = 0;
    setRound((value) => value + 1);
  }, []);

  return { state, restart };
}
