import type { Sql } from "postgres";
import { REVIEW_PROVIDER } from "./review-login";

// The account the App Store reviewer signs in with (provider 'review'). Its
// profile is complete from the start so the reviewer lands in the app, not in
// the profile setup; it never shows in anybody's Discover (matching prefilter)
// and is left out of the figures and the campaigns.

export const REVIEW_ACCOUNT_EMAIL = "app-review@mazl.app";

export interface ReviewAccount {
  readonly id: number;
  readonly email: string;
  readonly name: string | null;
  readonly picture: string | null;
  readonly provider: string;
  readonly is_active: boolean | null;
}

export async function ensureReviewAccount(db: Sql, username: string): Promise<{ account: ReviewAccount; isNew: boolean }> {
  const [account] = await db<(ReviewAccount & { created: boolean })[]>`
    INSERT INTO users (email, name, provider, provider_id, is_active, last_login_at)
    VALUES (${REVIEW_ACCOUNT_EMAIL}, 'Jonathan', ${REVIEW_PROVIDER}, ${username}, true, NOW())
    ON CONFLICT (provider, provider_id) DO UPDATE SET last_login_at = NOW()
    RETURNING id, email, name, picture, provider, is_active, (xmax = 0) AS created`;
  if (account === undefined) throw new Error("review account not written");
  // Inserted once: what the reviewer changes in the profile afterwards stays.
  await db`
    INSERT INTO profiles (user_id, display_name, birthdate, gender, looking_for, bio, location, denomination,
                          kashrut_level, shabbat_observance, relationship_intention, is_complete, age_min, age_max)
    VALUES (${account.id}, 'Jonathan', '1993-05-12', 'male', 'female',
            'Compte de démonstration pour la revue App Store.', 'Paris', 'Traditionaliste',
            'A la maison', 'Partiellement', 'serious', true, 18, 99)
    ON CONFLICT (user_id) DO NOTHING`;
  const { created, ...row } = account;
  return { account: row, isNew: created };
}

