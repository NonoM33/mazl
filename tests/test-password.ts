// Password of the throwaway users the dev endpoint creates for these tests.
// Drawn at run time: a hard-coded one in the repository was flagged by
// secret scanning (GitGuardian, PR #2), even though it only ever reached a
// local test server. The endpoint never checks it for an existing user.
export const TEST_PASSWORD = `pw-${crypto.randomUUID()}`;
