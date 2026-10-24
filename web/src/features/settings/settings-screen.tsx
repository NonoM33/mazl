import { useEffect } from "react";
import { ScreenHeader } from "../../app/shell";
import { AccountSection, AppearanceSection } from "./account-section";
import { DeleteAccountSection } from "./delete-account";
import { PlusSummarySection, VerificationSection } from "./membership-sections";
import { PrivacySection } from "./privacy-section";
import { SessionsSection } from "./sessions-section";
import { DiscreetSection, ShabbatSection } from "./shabbat-section";
import "./settings.css";

export function SettingsScreen() {
  useEffect(() => {
    const id = window.location.hash.slice(1);
    if (id.length > 0) document.getElementById(id)?.scrollIntoView();
  }, []);
  return (
    <>
      <ScreenHeader eyebrow="Réglages" title="Réglages" />
      <div className="screen-body"><div className="page-narrow stack gap-32">
        <AccountSection />
        <AppearanceSection />
        <ShabbatSection />
        <DiscreetSection />
        <SessionsSection />
        <PrivacySection />
        <VerificationSection />
        <PlusSummarySection />
        <DeleteAccountSection />
      </div></div>
    </>
  );
}
