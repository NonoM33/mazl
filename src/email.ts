import { Resend } from "resend";

const resend = new Resend(process.env.RESEND_API_KEY);

const APP_URL = process.env.APP_URL || "http://localhost:3000";

export async function sendConfirmationEmail(email: string, token: string) {
  const confirmUrl = `${APP_URL}/api/confirm?token=${token}`;

  try {
    const { data, error } = await resend.emails.send({
      from: "MZL <onboarding@resend.dev>",
      to: email,
      subject: "Confirme ton inscription sur MZL",
      html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f8f9fa; margin: 0; padding: 40px 20px; }
    .container { max-width: 500px; margin: 0 auto; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 4px 24px rgba(0,0,0,0.08); }
    .logo { font-size: 32px; font-weight: 700; color: #1a365d; text-align: center; margin-bottom: 8px; }
    .tagline { color: #c9a227; text-align: center; font-size: 14px; margin-bottom: 32px; }
    h1 { color: #1a365d; font-size: 24px; text-align: center; margin-bottom: 16px; }
    p { color: #4a5568; line-height: 1.6; text-align: center; }
    .btn { display: block; width: 100%; max-width: 280px; margin: 32px auto; padding: 16px 32px; background: linear-gradient(135deg, #1a365d 0%, #2c5282 100%); color: white; text-decoration: none; border-radius: 50px; font-weight: 600; text-align: center; }
    .footer { margin-top: 32px; padding-top: 24px; border-top: 1px solid #e2e8f0; text-align: center; color: #a0aec0; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">MZL</div>
    <div class="tagline">Trouve ton mazal, à ta façon</div>
    <h1>Confirme ton email</h1>
    <p>Merci de rejoindre la waitlist MZL ! Clique sur le bouton ci-dessous pour confirmer ton inscription.</p>
    <a href="${confirmUrl}" class="btn">Confirmer mon inscription</a>
    <p style="font-size: 13px; color: #718096;">Si tu n'as pas demandé cette inscription, ignore simplement cet email.</p>
    <div class="footer">
      © 2026 MZL - L'app de rencontre juive moderne
    </div>
  </div>
</body>
</html>
      `,
    });

    if (error) {
      console.error("Resend error:", error);
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (error: any) {
    console.error("Email send error:", error);
    return { success: false, error: error.message };
  }
}
