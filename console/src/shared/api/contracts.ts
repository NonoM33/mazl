// Contrats HTTP du serveur, importés en types seulement : la console n'embarque aucun code serveur.
export type {
  ApiFailure,
  ApiResponse,
  ApiSuccess,
  LoginResultDto,
  MeDto,
  MfaConfirmedDto,
  MfaEnrollmentDto,
} from "../../../../src/features/staff/presentation/dto";
export type {
  ConversationDto,
  DashboardDto,
  MemberFileDto,
  MemberRefDto,
  ReportDecisionBody,
  ReportDetailDto,
  ReportListItemDto,
  ReportPageDto,
  SanctionDto,
  SanctionInput,
} from "../../../../src/features/trust-safety/presentation/dto";
export type {
  DecisionGround,
  Priority,
  ReportReason,
  ReportStatus,
  RiskSignal,
  SanctionKind,
  StatementOfReasons,
} from "../../../../src/features/trust-safety/domain/types";
export type { Permission, StaffRole } from "../../../../src/features/staff/domain/roles";

// Réponse d'une décision ou d'une sanction : le code de contestation n'est rendu qu'une fois.
export interface DecisionResultDto {
  readonly reference?: string;
  readonly appealCode?: string;
}

export interface MemberSearchPageDto {
  readonly members: readonly {
    readonly id: number;
    readonly displayName: string | null;
    readonly email: string;
    readonly photoUrl: string | null;
    readonly active: boolean;
    readonly verification: "none" | "selfie" | "identity";
  }[];
  readonly total: number;
}
