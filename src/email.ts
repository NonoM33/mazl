import { Resend } from "resend";

const resendApiKey = process.env.RESEND_API_KEY;
if (!resendApiKey) {
  console.warn("RESEND_API_KEY is not set; emails will not be sent.");
}

const resend = resendApiKey ? new Resend(resendApiKey) : null;

const APP_URL = (process.env.APP_URL || "http://localhost:3000").replace(/\/$/, "");
const FROM_EMAIL = process.env.FROM_EMAIL || "hello@mazl.app";

function resolveBaseUrl(baseUrl?: string) {
  return (baseUrl || APP_URL || "https://mazl.app").replace(/\/$/, "");
}

export async function sendVerificationRequestEmail(params: {
  to: string;
  verificationToken: string;
  baseUrl?: string;
}) {
  if (!resend) return { success: false, error: "missing_resend_api_key" };

  const baseUrl = resolveBaseUrl(params.baseUrl);
  const verifyUrl = `${baseUrl}/verify?token=${params.verificationToken}`;

  const { data, error } = await resend.emails.send({
    from: `MAZL <${FROM_EMAIL}>`,
    to: params.to,
    subject: "Bienvenue sur MAZL — Vérifie ton profil",
    html: `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>MAZL — Vérification</title>
  </head>
  <body style="margin:0;background:#f6f7fb;font-family:Inter,system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;">
    <div style="max-width:560px;margin:0 auto;padding:28px 16px;">
      <div style="background:#ffffff;border-radius:16px;box-shadow:0 10px 40px rgba(0,0,0,.06);padding:28px;">
        <div style="font-weight:800;font-size:22px;letter-spacing:-0.5px;background:linear-gradient(135deg,#6C5CE7,#FD79A8);-webkit-background-clip:text;background-clip:text;color:transparent;">
          MAZL
        </div>
        <h1 style="margin:12px 0 8px;font-size:22px;color:#2D3436;">Bienvenue sur la waitlist</h1>
        <p style="margin:0 0 18px;color:#636E72;line-height:1.6;">
          Pour accéder en priorité à l’app, on te demande une vérification rapide.
        </p>

        <div style="background:#F8F9FE;border:1px solid rgba(108,92,231,.15);border-radius:14px;padding:14px 14px;margin:16px 0;">
          <div style="font-weight:700;color:#2D3436;margin-bottom:6px;">Étape 1 (obligatoire)</div>
          <div style="color:#636E72;">Selfie + pièce d’identité (CNI / passeport)</div>
          <div style="height:8px;"></div>
          <div style="font-weight:700;color:#2D3436;margin-bottom:6px;">Étape 2 (optionnelle)</div>
          <div style="color:#636E72;">Document communautaire pour le badge “Vérifié+” (ex: ketouba, certificat, carte synagogue…)</div>
        </div>

        <a href="${verifyUrl}" style="display:inline-block;background:linear-gradient(135deg,#6C5CE7,#FD79A8);color:white;text-decoration:none;padding:14px 18px;border-radius:999px;font-weight:700;">
          Envoyer mes documents
        </a>

        <p style="margin:18px 0 0;color:#B2BEC3;font-size:12px;line-height:1.5;">
          Si tu n’es pas à l’origine de cette demande, ignore cet email.
        </p>
      </div>
      <p style="margin:14px 0 0;color:#B2BEC3;font-size:12px;text-align:center;">© 2026 MAZL</p>
    </div>
  </body>
</html>
    `.trim(),
  });

  if (error) return { success: false, error: error.message };
  return { success: true, data };
}

export async function sendReuploadRequestedEmail(params: {
  to: string;
  verificationToken: string;
  reason?: string;
  rejectedTypes?: string[];
  baseUrl?: string;
}) {
  if (!resend) return { success: false, error: "missing_resend_api_key" };

  const baseUrl = resolveBaseUrl(params.baseUrl);
  const verifyUrl = `${baseUrl}/verify?token=${params.verificationToken}`;
  const reason = (params.reason || "").trim();
  const rejectedTypes = Array.isArray(params.rejectedTypes) ? params.rejectedTypes : [];

  const reasonBlock = reason
    ? `<div style="margin-top:12px;background:#fff7ed;border:1px solid rgba(253,186,116,.5);border-radius:14px;padding:12px 14px;color:#7c2d12;">
        <div style="font-weight:800;margin-bottom:6px;">Motif</div>
        <div style="white-space:pre-wrap;line-height:1.5;">${escapeHtml(reason)}</div>
      </div>`
    : ``;

  const rejectedList = rejectedTypes.length
    ? `<div style="margin-top:12px;background:#F8F9FE;border:1px solid rgba(108,92,231,.15);border-radius:14px;padding:12px 14px;">
        <div style="font-weight:800;color:#2D3436;margin-bottom:6px;">Documents à renvoyer</div>
        <ul style="margin:0;padding-left:18px;color:#636E72;line-height:1.6;">
          ${rejectedTypes.map((t) => `<li>${escapeHtml(humanDocType(t))}</li>`).join('')}
        </ul>
      </div>`
    : ``;

  const { data, error } = await resend.emails.send({
    from: `MAZL <${FROM_EMAIL}>`,
    to: params.to,
    subject: "MAZL — Documents à renvoyer",
    html: `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>MAZL — Re-upload</title>
  </head>
  <body style="margin:0;background:#f6f7fb;font-family:Inter,system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;">
    <div style="max-width:560px;margin:0 auto;padding:28px 16px;">
      <div style="background:#ffffff;border-radius:16px;box-shadow:0 10px 40px rgba(0,0,0,.06);padding:28px;">
        <div style="font-weight:800;font-size:22px;letter-spacing:-0.5px;background:linear-gradient(135deg,#6C5CE7,#FD79A8);-webkit-background-clip:text;background-clip:text;color:transparent;">MAZL</div>
        <h1 style="margin:12px 0 8px;font-size:22px;color:#2D3436;">Documents à renvoyer</h1>
        <p style="margin:0 0 14px;color:#636E72;line-height:1.6;">
          On a besoin que tu renvoies tes documents de vérification.
        </p>
        ${reasonBlock}
        ${rejectedList}

        <div style="margin-top:16px;background:#F8F9FE;border:1px solid rgba(108,92,231,.15);border-radius:14px;padding:14px 14px;">
          <div style="font-weight:800;color:#2D3436;margin-bottom:6px;">Requis</div>
          <div style="color:#636E72;">Selfie + CNI recto + CNI verso</div>
        </div>


        <a href="${verifyUrl}" style="margin-top:16px;display:inline-block;background:linear-gradient(135deg,#6C5CE7,#FD79A8);color:white;text-decoration:none;padding:14px 18px;border-radius:999px;font-weight:700;">
          Renvoyer mes documents
        </a>

        <p style="margin:18px 0 0;color:#B2BEC3;font-size:12px;line-height:1.5;">© 2026 MAZL</p>
      </div>
    </div>
  </body>
</html>
    `.trim(),
  });

  if (error) return { success: false, error: error.message };
  return { success: true, data };
}

function humanDocType(type: string) {
  switch (type) {
    case "selfie_id":
      return "Selfie + pièce d’identité";
    case "id_card_front":
      return "CNI / passeport (recto)";
    case "id_card_back":
      return "CNI / passeport (verso)";
    case "community_doc":
      return "Document communautaire";
    default:
      return type;
  }
}

function escapeHtml(input: string) {
  return input
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

export async function sendProfileApprovedEmail(params: { to: string; baseUrl?: string; level?: "verified" | "verified_plus" }) {
  if (!resend) return { success: false, error: "missing_resend_api_key" };

  const baseUrl = resolveBaseUrl(params.baseUrl);
  const level = params.level || "verified";

  const badge =
    level === "verified_plus"
      ? "✅ Profil vérifié+"
      : "✅ Profil vérifié";

  const { data, error } = await resend.emails.send({
    from: `MAZL <${FROM_EMAIL}>`,
    to: params.to,
    subject: "MAZL — Profil vérifié ✅",
    html: `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>MAZL — Profil vérifié</title>
  </head>
  <body style="margin:0;background:#f6f7fb;font-family:Inter,system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;">
    <div style="max-width:560px;margin:0 auto;padding:28px 16px;">
      <div style="background:#ffffff;border-radius:16px;box-shadow:0 10px 40px rgba(0,0,0,.06);padding:28px;">
        <div style="font-weight:800;font-size:22px;letter-spacing:-0.5px;background:linear-gradient(135deg,#6C5CE7,#FD79A8);-webkit-background-clip:text;background-clip:text;color:transparent;">MAZL</div>
        <h1 style="margin:12px 0 8px;font-size:22px;color:#2D3436;">Félicitations 🎉</h1>
        <p style="margin:0 0 14px;color:#636E72;line-height:1.6;">Ton profil est validé par notre équipe.</p>
        <div style="margin-top:12px;background:#F0FDF4;border:1px solid rgba(0,184,148,.35);border-radius:14px;padding:12px 14px;color:#065f46;font-weight:800;">${badge}</div>

        <p style="margin:16px 0 0;color:#636E72;line-height:1.6;">On te tient au courant dès l’ouverture de l’app. Merci d’être parmi les premiers 🙏</p>

        <a href="${baseUrl}" style="margin-top:16px;display:inline-block;background:linear-gradient(135deg,#6C5CE7,#FD79A8);color:white;text-decoration:none;padding:14px 18px;border-radius:999px;font-weight:700;">Retourner sur MAZL</a>

        <p style="margin:18px 0 0;color:#B2BEC3;font-size:12px;line-height:1.5;">© 2026 MAZL</p>
      </div>
    </div>
  </body>
</html>
    `.trim(),
  });

  if (error) return { success: false, error: error.message };
  return { success: true, data };
}
