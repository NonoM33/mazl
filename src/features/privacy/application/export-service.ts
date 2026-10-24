import { buildExportDocument, type ExportDocument } from "../domain/export-document";
import type { ExportReader } from "./ports";

export interface MemberExport {
  readonly document: ExportDocument;
  readonly filename: string;
}

// GDPR art. 15 and 20: the member's own data in a machine-readable file.
export class ExportService {
  constructor(
    private readonly reader: ExportReader,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async export(userId: number): Promise<MemberExport> {
    const generatedAt = this.now();
    const sections = await this.reader.read(userId);
    const day = generatedAt.toISOString().slice(0, 10);
    return {
      document: buildExportDocument(sections, generatedAt),
      filename: `mazl-export-${userId}-${day}.json`,
    };
  }
}
