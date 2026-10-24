import type { ReactElement } from "react";
import type { MemberRefDto } from "../shared/api/contracts";
import { memberName } from "../shared/format";
import { BlurredImage } from "../shared/ui/BlurredImage";

export function MemberCell({ member }: { readonly member: MemberRefDto }): ReactElement {
  return (
    <span className="member-cell">
      <BlurredImage src={member.photoUrl} name={memberName(member)} size={32} round />
      <span className="member-cell-text">
        <span className="member-cell-name">{memberName(member)}</span>
        <span className="member-cell-id">n°&nbsp;{member.id}</span>
      </span>
    </span>
  );
}
