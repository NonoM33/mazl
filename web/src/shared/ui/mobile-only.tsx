import { Smartphone } from "lucide-react";
import { QrCode } from "./qr-code";

// Functions kept on the phone (selfie and chip verification,
// precise location, purchases through the App Store): the web says so and
// offers a QR code that opens the app. It never leads to a purchase
// (docs/web/adr/W05-regles-app-store.md).

// App Store page of MAZL (app id 6758543555, docs/premium/APP-STORE-CONNECT.md):
// on an iPhone with the app installed, the page offers « Ouvrir ».
export const APP_LINK = "https://apps.apple.com/app/id6758543555";

const QR_LABEL = "QR code : ouvrir MAZL sur votre téléphone";

export function MobileOnly({ title, children }: { readonly title: string; readonly children: string }) {
  return (
    <div className="card-surface" style={{ padding: 24, display: "flex", gap: 24, alignItems: "center" }}>
      <QrCode value={APP_LINK} size={120} label={QR_LABEL} />
      <div className="stack gap-8">
        <div className="inline gap-8"><Smartphone size={18} aria-hidden="true" /><h3 className="title-m">{title}</h3></div>
        <p className="body-s">{children}</p>
        <p className="label-m">Scannez avec l'appareil photo de votre téléphone.</p>
      </div>
    </div>
  );
}
