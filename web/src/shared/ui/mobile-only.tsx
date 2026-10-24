import { useState } from "react";
import { QrCode as QrIcon, Smartphone } from "lucide-react";
import { QrCode } from "./qr-code";

// Functions kept on the phone (selfie and chip verification, video calls,
// precise location, purchases through the App Store): the web says so and
// offers a QR code that opens the app. It never leads to a purchase
// (docs/web/adr/W05-regles-app-store.md).

// App Store page of MAZL (app id 6758543555, docs/premium/APP-STORE-CONNECT.md):
// on an iPhone with the app installed, the page offers « Ouvrir ».
export const APP_LINK = "https://apps.apple.com/app/id6758543555";

const QR_LABEL = "QR code : ouvrir MAZL sur votre téléphone";

// `compact` fits a narrow column: one line of text, the QR code on demand.
export function MobileOnly({ title, children, compact = false }: { readonly title: string; readonly children: string; readonly compact?: boolean }) {
  const [showQr, setShowQr] = useState(false);
  if (compact) {
    return (
      <div className="card-surface stack gap-8" style={{ padding: 16 }}>
        <div className="inline gap-8"><Smartphone size={16} aria-hidden="true" /><h3 className="title-s">{title}</h3></div>
        <p className="body-s">{children}</p>
        {showQr ? (
          <div className="center"><QrCode value={APP_LINK} size={120} label={QR_LABEL} /></div>
        ) : (
          <button type="button" className="btn btn-ghost btn-sm" style={{ alignSelf: "flex-start", paddingLeft: 0 }} onClick={() => setShowQr(true)}>
            <QrIcon size={16} aria-hidden="true" />Ouvrir l'app avec un QR code
          </button>
        )}
      </div>
    );
  }
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
