// Vocabulary of trust & safety (docs/backoffice/CADRAGE.md §6). Pure data.

// Categories a member can pick in the app (src/shared/http/validation.ts
// REPORT_REASONS) plus the ones raised from a message report.
export const REPORT_REASONS = [
  "underage",
  "offline_behavior",
  "harassment",
  "scam",
  "fake_profile",
  "inappropriate_photos",
  "spam",
  "other",
] as const;
export type ReportReason = (typeof REPORT_REASONS)[number];

// P1 = act now (minor, physical danger), P4 = when time allows.
export const PRIORITIES = ["P1", "P2", "P3", "P4"] as const;
export type Priority = (typeof PRIORITIES)[number];

export const REPORT_STATUSES = ["pending", "in_review", "actioned", "dismissed"] as const;
export type ReportStatus = (typeof REPORT_STATUSES)[number];

// Graduated sanctions, lightest first.
export const SANCTION_KINDS = ["warning", "restriction", "suspension", "ban"] as const;
export type SanctionKind = (typeof SANCTION_KINDS)[number];

// Normalised grounds of a decision: what the statement of reasons cites
// (terms of use clause), whatever the free text of the report said.
export const DECISION_GROUNDS = [
  "minor_on_platform",
  "threat_or_violence",
  "sexual_content",
  "harassment",
  "hate_speech",
  "scam_or_fraud",
  "impersonation",
  "fake_profile",
  "commercial_spam",
  "off_platform_solicitation",
  "inappropriate_photo",
  "illegal_content",
  "other_terms_breach",
] as const;
export type DecisionGround = (typeof DECISION_GROUNDS)[number];

export const APPEAL_STATUSES = ["pending", "upheld", "overturned"] as const;
export type AppealStatus = (typeof APPEAL_STATUSES)[number];

export const AUTHORITY_KINDS = ["judicial_requisition", "police_request", "pharos", "dsa_art18_notice", "other"] as const;
export type AuthorityKind = (typeof AUTHORITY_KINDS)[number];

export const AUTHORITY_STATUSES = ["received", "in_progress", "answered", "refused"] as const;
export type AuthorityStatus = (typeof AUTHORITY_STATUSES)[number];

// DSA art. 17 — the statement of reasons given to the member for every
// restriction. Built by the domain, stored with the sanction, never edited.
export interface StatementOfReasons {
  readonly reference: string;
  readonly decision: SanctionKind;
  // What is restricted and for how long ("compte suspendu jusqu'au 12/11/2026").
  readonly scope: string;
  readonly facts: string;
  readonly ground: DecisionGround;
  // Clause of the terms of use or legal basis, in French.
  readonly groundText: string;
  // Always false for MAZL: every decision is taken by a person.
  readonly automatedDetection: boolean;
  readonly automatedDecision: false;
  // How to contest: internal appeal (deadline), out-of-court body, court.
  readonly redress: string;
  readonly issuedAt: string;
}

// A weak signal of romance scam / fake profile shown to the moderator. Never
// decides anything alone.
export interface RiskSignal {
  readonly code: "money_request" | "crypto" | "off_platform" | "copy_paste" | "new_account" | "many_reports" | "many_blocks" | "no_verification";
  readonly label: string;
  readonly weight: number;
  readonly evidence: string;
}
