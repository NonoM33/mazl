// Additional authenticated data bound to every sealed document (CONTRAT §2.4):
// a file copied under another document's row cannot be opened.
export function documentContext(documentId: number): string {
  return `document:${documentId}`;
}

// New files live under documents/ with a name that carries no information.
export function newEncryptedFileName(): string {
  return `documents/${crypto.randomUUID()}.enc`;
}
