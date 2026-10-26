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
export type {
  MatchingStateDto,
  ParamsVersionDto,
  PreviewRequest,
  PreviewResponse,
  VersionPageDto,
} from "../../../../src/features/matching/presentation/dto";
export type {
  Criterion,
  MatchingParams,
  NumericParamSpec,
  OrdinalScale,
  ParamGroup,
  ReciprocityMode,
  ScaleName,
} from "../../../../src/features/matching/domain/params";
export type { MatchProfile } from "../../../../src/features/matching/domain/profile";
export type {
  CriterionScore,
  DirectionalScore,
  ExclusionReason,
  Multiplier,
  MultiplierKey,
  RankedCandidate,
  RankingResult,
} from "../../../../src/features/matching/domain/ranking";
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
