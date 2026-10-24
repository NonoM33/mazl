// Credential of the throwaway users the dev endpoint creates for these tests.
// Drawn at run time, with no literal in the repository: secret scanning
// (GitGuardian, PR #2) flags any hard-coded value, even one that only ever
// reached a local test server. The endpoint never checks it for an existing user.
export const THROWAWAY_CREDENTIAL = crypto.randomUUID();
