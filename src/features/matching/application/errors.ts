// Failures of the matching tuning, as values the routes map to HTTP codes.

export class InvalidParamsError extends Error {
  constructor(readonly problems: readonly string[]) {
    super(problems.join(" ; "));
    this.name = "InvalidParamsError";
  }
}

export class VersionNotFoundError extends Error {
  constructor(readonly versionId: number) {
    super(`Version ${versionId} introuvable`);
    this.name = "VersionNotFoundError";
  }
}

export class VariantIsActiveError extends Error {
  constructor(readonly versionId: number) {
    super(`La version ${versionId} est déjà la version active : elle ne peut pas être sa propre variante`);
    this.name = "VariantIsActiveError";
  }
}

export class NoAbTestError extends Error {
  constructor() {
    super("Aucun test A/B en cours");
    this.name = "NoAbTestError";
  }
}

// A stored version whose parameters no longer pass validation: never executed.
export class CorruptVersionError extends Error {
  constructor(readonly versionId: number, readonly problems: readonly string[]) {
    super(`La version ${versionId} contient des paramètres invalides : ${problems.join(" ; ")}`);
    this.name = "CorruptVersionError";
  }
}

export class InvalidPreviewError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InvalidPreviewError";
  }
}
