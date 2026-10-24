import type { ReactElement } from "react";
import { EmptyState } from "../shared/ui/Feedback";
import { PageHeader } from "../shared/ui/PageHeader";
import type { SectionDef } from "./permissions";

export function ComingSoon({ section }: { readonly section: SectionDef }): ReactElement {
  return (
    <>
      <PageHeader eyebrow="Bientôt" title={section.label} />
      <div className="page-body">
        <EmptyState icon="clock" title="Cet écran arrive bientôt">
          {section.description} Il sera ajouté dans un prochain lot de la console.
        </EmptyState>
      </div>
    </>
  );
}
