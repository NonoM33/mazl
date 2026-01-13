import { Resend } from "resend";

const resendApiKey = process.env.RESEND_API_KEY;
if (!resendApiKey) {
  console.warn("RESEND_API_KEY is not set; emails will not be sent.");
}

const resend = new Resend(resendApiKey);

const APP_URL = (process.env.APP_URL || "http://localhost:3000").replace(/\/$/, "");
const FROM_EMAIL = process.env.FROM_EMAIL || "hello@mazl.app";

export async function sendVerificationRequestEmail(params: {
  to: string;
  verificationToken: string;
  baseUrl?: string;
}) {
  if (!resendApiKey) return { success: false, error: "missing_resend_api_key" };

  const baseUrl = (params.baseUrl || APP_URL || "https://mazl.app").replace(/\/$/, "");
  const verifyUrl = `${baseUrl}/verify?token=${params.verificationToken}`;

  const { data, error } = await resend.emails.send({
    from: `MZL <${FROM_EMAIL}>`,
    to: params.to,
    subject: "Bienvenue sur MZL — Vérifie ton profil",
    html: `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>MZL — Vérification</title>
  </head>
  <body style="margin:0;background:#f6f7fb;font-family:Inter,system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;">
    <div style="max-width:560px;margin:0 auto;padding:28px 16px;">
      <div style="background:#ffffff;border-radius:16px;box-shadow:0 10px 40px rgba(0,0,0,.06);padding:28px;">
        <div style="font-weight:800;font-size:22px;letter-spacing:-0.5px;background:linear-gradient(135deg,#6C5CE7,#FD79A8);-webkit-background-clip:text;background-clip:text;color:transparent;">
          MZL
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
      <p style="margin:14px 0 0;color:#B2BEC3;font-size:12px;text-align:center;">© 2026 MZL</p>
    </div>
  </body>
</html>
    `.trim(),
  });

  if (error) return { success: false, error: error.message };
  return { success: true, data };
}
