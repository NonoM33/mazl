import type { AppealsService } from "../application/appeals-service";
import type { MembersService } from "../application/members-service";
import type { OverviewService } from "../application/overview-service";
import type { AuthorityRepository } from "../application/ports";
import type { ReportsService } from "../application/reports-service";
import type { SanctionsService } from "../application/sanctions-service";
import type { AuditLog } from "../../audit/application/ports";
import type { RequirePermission } from "../../staff/application/ports";

export interface TrustSafetyServices {
  readonly reports: ReportsService;
  readonly sanctions: SanctionsService;
  readonly members: MembersService;
  readonly appeals: AppealsService;
  readonly overview: OverviewService;
  readonly authorities: AuthorityRepository;
}

export interface RouteDeps {
  readonly requirePermission: RequirePermission;
  readonly audit: Pick<AuditLog, "record">;
  readonly services: TrustSafetyServices;
}
