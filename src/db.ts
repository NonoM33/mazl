import postgres from "postgres";
import { applyTestProfiles } from "./features/fixtures/test-profiles";
import { ensureReviewAccount } from "./features/auth/review/review-account";
import { readReviewLoginConfig } from "./features/auth/review/review-login";
import { applyTestEvents } from "./features/fixtures/test-events";
import { createCreditTables, eraseCredits } from "./features/credits/infra/schema";
import { badgeColumns, primaryPhotoColumns } from "./features/media/infra/sql-fragments";
import { publicPhotoUrls, withPublicPicture } from "./features/media/application/photo-urls";
import { publicPicturesFor } from "./features/media/infra/public-pictures";
import { isProfileComplete } from "./features/profile/domain/profile-completeness";
import { isDevelopmentEnvironment } from "./shared/runtime/development-environment";
import { COUPLE_ACTIVITY_SEEDS, COUPLE_EVENT_SEEDS } from "./features/fixtures/couple-catalogue";

// Production must name its database: a silent fallback to the local
// development credentials would hide a broken deployment.
if (process.env.NODE_ENV === "production" && !process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL must be set in production");
}
const connectionString = process.env.DATABASE_URL || "postgres://postgres:postgres@localhost:5432/mazl";

export const sql = postgres(connectionString);

export async function initDb() {
  await sql`
    CREATE TABLE IF NOT EXISTS waitlist (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) UNIQUE NOT NULL,
      token VARCHAR(64) NOT NULL,
      status VARCHAR(20) DEFAULT 'pending',
      created_at TIMESTAMP DEFAULT NOW(),
      confirmed_at TIMESTAMP,
      verification_token VARCHAR(128),
      verification_status VARCHAR(20) DEFAULT 'pending',
      verification_requested_at TIMESTAMP,
      documents_submitted_at TIMESTAMP,
      verified_at TIMESTAMP,
      os VARCHAR(20)
    )
  `;

  // Backward-compatible migrations
  await sql`ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS verification_token VARCHAR(128)`;
  await sql`ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) DEFAULT 'pending'`;
  await sql`ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS verification_requested_at TIMESTAMP`;
  await sql`ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS documents_submitted_at TIMESTAMP`;
  await sql`ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP`;
  await sql`ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS os VARCHAR(20)`;
  // When the current verification_token was issued: the emailed link expires 30
  // days later. The default stamps the rows that predate the column with the
  // migration time, so their links stay valid for 30 days from then.
  await sql`ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS verification_token_created_at TIMESTAMP NOT NULL DEFAULT NOW()`;

  await sql`
    CREATE TABLE IF NOT EXISTS documents (
      id SERIAL PRIMARY KEY,
      waitlist_id INTEGER REFERENCES waitlist(id) ON DELETE CASCADE,
      type VARCHAR(50) NOT NULL,
      filename VARCHAR(255) NOT NULL,
      original_name VARCHAR(255),
      mime_type VARCHAR(100),
      status VARCHAR(20) DEFAULT 'pending',
      created_at TIMESTAMP DEFAULT NOW(),
      reviewed_at TIMESTAMP,
      reviewer_notes TEXT
    )
  `;

  // Users table for OAuth authentication
  await sql`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) UNIQUE NOT NULL,
      name VARCHAR(255),
      picture TEXT,
      provider VARCHAR(20) NOT NULL,
      provider_id VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW(),
      last_login_at TIMESTAMP DEFAULT NOW(),
      is_active BOOLEAN DEFAULT true,
      UNIQUE(provider, provider_id)
    )
  `;

  // User profiles table for dating app
  await sql`
    CREATE TABLE IF NOT EXISTS profiles (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE UNIQUE,
      display_name VARCHAR(100),
      birthdate DATE,
      gender VARCHAR(20),
      bio TEXT,
      location VARCHAR(255),
      latitude DECIMAL(10, 8),
      longitude DECIMAL(11, 8),
      denomination VARCHAR(50),
      kashrut_level VARCHAR(50),
      shabbat_observance VARCHAR(50),
      looking_for VARCHAR(50),
      age_min INTEGER DEFAULT 18,
      age_max INTEGER DEFAULT 99,
      distance_max INTEGER DEFAULT 100,
      is_complete BOOLEAN DEFAULT false,
      is_verified BOOLEAN DEFAULT false,
      verification_level VARCHAR(20) DEFAULT 'none',
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Profile photos
  await sql`
    CREATE TABLE IF NOT EXISTS profile_photos (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      url TEXT NOT NULL,
      position INTEGER DEFAULT 0,
      is_primary BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Swipes table
  await sql`
    CREATE TABLE IF NOT EXISTS swipes (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      target_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      action VARCHAR(20) NOT NULL,
      created_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(user_id, target_user_id)
    )
  `;

  // Matches table
  await sql`
    CREATE TABLE IF NOT EXISTS matches (
      id SERIAL PRIMARY KEY,
      user1_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      user2_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      created_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(user1_id, user2_id)
    )
  `;

  // Profile prompts (question/answer cards on a user's profile, max 3)
  await sql`
    CREATE TABLE IF NOT EXISTS profile_prompts (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      prompt_id VARCHAR(50) NOT NULL,
      answer TEXT NOT NULL,
      position INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Legacy gesture-verification attempts (US-TS-03), used by
  // POST /api/verification/start only. The 3-per-day quota is enforced by
  // counting today's rows (see startVerification below).
  await sql`
    CREATE TABLE IF NOT EXISTS verification_attempts (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      gesture_id VARCHAR(30) NOT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'pending',
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `;

  // Boosts table (profile boost: temporarily prioritized in discover feed)
  await sql`
    CREATE TABLE IF NOT EXISTS boosts (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      activated_at TIMESTAMP NOT NULL DEFAULT NOW(),
      expires_at TIMESTAMP NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `;
  // When the member was pushed that this Boost ended (features/push).
  await sql`ALTER TABLE boosts ADD COLUMN IF NOT EXISTS end_notified_at TIMESTAMP`;

  // Add new columns if they don't exist
  await sql`ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false`;
  await sql`ALTER TABLE profiles ADD COLUMN IF NOT EXISTS verification_level VARCHAR(20) DEFAULT 'none'`;
  // What the member is looking for (marriage, serious…), weighed by the matching engine.
  await sql`ALTER TABLE profiles ADD COLUMN IF NOT EXISTS relationship_intention VARCHAR(30)`;

  // Conversations table (created automatically when match happens)
  await sql`
    CREATE TABLE IF NOT EXISTS conversations (
      id SERIAL PRIMARY KEY,
      match_id INTEGER REFERENCES matches(id) ON DELETE CASCADE,
      user1_id INTEGER REFERENCES users(id),
      user2_id INTEGER REFERENCES users(id),
      last_message_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Messages table
  await sql`
    CREATE TABLE IF NOT EXISTS messages (
      id SERIAL PRIMARY KEY,
      conversation_id INTEGER REFERENCES conversations(id) ON DELETE CASCADE,
      sender_id INTEGER REFERENCES users(id),
      content TEXT NOT NULL,
      is_read BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Events table
  await sql`
    CREATE TABLE IF NOT EXISTS events (
      id SERIAL PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      description TEXT,
      event_type VARCHAR(50),
      location VARCHAR(255),
      address TEXT,
      latitude DECIMAL(10, 8),
      longitude DECIMAL(11, 8),
      date DATE NOT NULL,
      time TIME,
      end_time TIME,
      price DECIMAL(10, 2) DEFAULT 0,
      currency VARCHAR(3) DEFAULT 'EUR',
      max_attendees INTEGER,
      image_url TEXT,
      organizer_id INTEGER REFERENCES users(id),
      is_published BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Event RSVPs table
  await sql`
    CREATE TABLE IF NOT EXISTS event_rsvps (
      id SERIAL PRIMARY KEY,
      event_id INTEGER REFERENCES events(id) ON DELETE CASCADE,
      user_id INTEGER REFERENCES users(id),
      status VARCHAR(20) DEFAULT 'going',
      paid BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(event_id, user_id)
    )
  `;

  // "Coming soon" events (features/events): shown, but every registration is
  // refused until an administrator opens them. fixture_key marks the fake
  // events of the TestFlight phase (features/fixtures/test-events).
  await sql`ALTER TABLE events ADD COLUMN IF NOT EXISTS availability VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (availability IN ('open', 'coming_soon'))`;
  await sql`ALTER TABLE events ADD COLUMN IF NOT EXISTS fixture_key VARCHAR(64)`;
  await sql`CREATE UNIQUE INDEX IF NOT EXISTS events_fixture_key_key ON events (fixture_key)`;
  // « Me prévenir »: the members to tell when a coming soon event opens.
  await sql`
    CREATE TABLE IF NOT EXISTS event_open_alerts (
      event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      notified_at TIMESTAMP,
      PRIMARY KEY (event_id, user_id)
    )
  `;

  // Subscriptions table (Apple App Store purchases)
  await sql`
    CREATE TABLE IF NOT EXISTS subscriptions (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id) UNIQUE,
      plan_type VARCHAR(50),
      status VARCHAR(20) DEFAULT 'active',
      revenuecat_id VARCHAR(255), -- legacy RevenueCat column: kept for existing rows, no longer written
      started_at TIMESTAMP,
      expires_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `;
  await sql`ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS store VARCHAR(20)`;
  await sql`ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS product_id VARCHAR(100)`;
  await sql`ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS original_transaction_id VARCHAR(64)`;
  await sql`
    CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriptions_original_tx
    ON subscriptions(original_transaction_id) WHERE original_transaction_id IS NOT NULL
  `;

  // Boost and super like credits held by the server (docs/premium/CREDITS.md)
  await createCreditTables(sql);

  // Couples table for couple mode
  await sql`
    CREATE TABLE IF NOT EXISTS couples (
      id SERIAL PRIMARY KEY,
      user1_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      user2_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      status VARCHAR(20) DEFAULT 'active',
      relationship_status VARCHAR(20) DEFAULT 'dating',
      started_at DATE,
      met_on_mazl_at DATE,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(user1_id, user2_id)
    )
  `;

  // A member is in ONE active couple, whichever column (user1_id / user2_id)
  // holds them. Two partial unique indexes cannot say that (a member can be
  // user2_id of one row and user1_id of another), so a trigger enforces it.
  // It takes a transaction-scoped advisory lock per member, in id order, so two
  // concurrent acceptances serialise instead of both passing the check.
  // First, repair any legacy duplicate: the older active couple of a member who
  // also belongs to a newer active one is ended (nothing is deleted).
  await sql`
    UPDATE couples old SET status = 'ended', updated_at = NOW()
    WHERE old.status = 'active' AND EXISTS (
      SELECT 1 FROM couples newer
      WHERE newer.status = 'active' AND newer.id > old.id
        AND (newer.user1_id IN (old.user1_id, old.user2_id)
          OR newer.user2_id IN (old.user1_id, old.user2_id))
    )
  `;
  await sql`
    CREATE OR REPLACE FUNCTION enforce_single_active_couple() RETURNS trigger AS $$
    BEGIN
      IF NEW.status = 'active' THEN
        PERFORM pg_advisory_xact_lock(7301, LEAST(NEW.user1_id, NEW.user2_id));
        PERFORM pg_advisory_xact_lock(7301, GREATEST(NEW.user1_id, NEW.user2_id));
        IF EXISTS (
          SELECT 1 FROM couples c
          WHERE c.status = 'active' AND c.id IS DISTINCT FROM NEW.id
            AND (c.user1_id IN (NEW.user1_id, NEW.user2_id)
              OR c.user2_id IN (NEW.user1_id, NEW.user2_id))
        ) THEN
          RAISE EXCEPTION 'a member is already in an active couple' USING ERRCODE = '23505';
        END IF;
      END IF;
      RETURN NEW;
    END
    $$ LANGUAGE plpgsql
  `;
  await sql`DROP TRIGGER IF EXISTS trg_single_active_couple ON couples`;
  await sql`
    CREATE TRIGGER trg_single_active_couple
    BEFORE INSERT OR UPDATE OF user1_id, user2_id, status ON couples
    FOR EACH ROW EXECUTE FUNCTION enforce_single_active_couple()
  `;

  // Couple daily questions
  await sql`
    CREATE TABLE IF NOT EXISTS couple_questions (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER REFERENCES couples(id) ON DELETE CASCADE,
      question TEXT NOT NULL,
      category VARCHAR(50),
      user1_answer TEXT,
      user2_answer TEXT,
      asked_at DATE DEFAULT CURRENT_DATE,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Couple milestones
  await sql`
    CREATE TABLE IF NOT EXISTS couple_milestones (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER REFERENCES couples(id) ON DELETE CASCADE,
      milestone_type VARCHAR(50) NOT NULL,
      achieved_at TIMESTAMP DEFAULT NOW(),
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Couple requests (demande / acceptation de couple)
  await sql`
    CREATE TABLE IF NOT EXISTS couple_requests (
      id SERIAL PRIMARY KEY,
      requester_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      target_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      status VARCHAR(20) NOT NULL DEFAULT 'pending',
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_couple_requests_target ON couple_requests(target_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_couple_requests_requester ON couple_requests(requester_id)`;
  // Prevent duplicate pending requests between the same ordered pair.
  await sql`
    CREATE UNIQUE INDEX IF NOT EXISTS uniq_couple_requests_pending
    ON couple_requests(requester_id, target_id)
    WHERE status = 'pending'
  `;

  // Per-user conversation archiving (couple mode hides other convos).
  // Scoped to the archiving user only; never mutates the shared conversation row.
  await sql`
    CREATE TABLE IF NOT EXISTS archived_conversations (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
      created_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(user_id, conversation_id)
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_archived_conversations_user ON archived_conversations(user_id)`;

  // ============ ADMIN BACK-OFFICE TABLES ============

  // User bans
  await sql`
    CREATE TABLE IF NOT EXISTS user_bans (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      reason TEXT NOT NULL,
      banned_by VARCHAR(255),
      banned_at TIMESTAMP DEFAULT NOW(),
      expires_at TIMESTAMP,
      is_permanent BOOLEAN DEFAULT false,
      unbanned_at TIMESTAMP,
      unbanned_by VARCHAR(255)
    )
  `;

  // Admin notes on users
  await sql`
    CREATE TABLE IF NOT EXISTS admin_notes (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      admin_email VARCHAR(255) NOT NULL,
      note TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // User reports (signalements)
  await sql`
    CREATE TABLE IF NOT EXISTS reports (
      id SERIAL PRIMARY KEY,
      reporter_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      reported_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      reason VARCHAR(100) NOT NULL,
      details TEXT,
      status VARCHAR(20) DEFAULT 'pending',
      handled_by VARCHAR(255),
      handled_at TIMESTAMP,
      action_taken VARCHAR(100),
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Blocked users (user-to-user blocking)
  await sql`
    CREATE TABLE IF NOT EXISTS blocked_users (
      id SERIAL PRIMARY KEY,
      blocker_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      blocked_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at TIMESTAMP DEFAULT NOW(),
      UNIQUE (blocker_id, blocked_id)
    )
  `;

  // Campaigns (email/push)
  await sql`
    CREATE TABLE IF NOT EXISTS campaigns (
      id SERIAL PRIMARY KEY,
      type VARCHAR(20) NOT NULL,
      title VARCHAR(255) NOT NULL,
      subject VARCHAR(255),
      content TEXT NOT NULL,
      segment_id INTEGER,
      status VARCHAR(20) DEFAULT 'draft',
      scheduled_at TIMESTAMP,
      sent_at TIMESTAMP,
      created_by VARCHAR(255),
      stats_sent INTEGER DEFAULT 0,
      stats_opened INTEGER DEFAULT 0,
      stats_clicked INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Campaign recipients tracking
  await sql`
    CREATE TABLE IF NOT EXISTS campaign_recipients (
      id SERIAL PRIMARY KEY,
      campaign_id INTEGER REFERENCES campaigns(id) ON DELETE CASCADE,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      email VARCHAR(255),
      sent_at TIMESTAMP,
      opened_at TIMESTAMP,
      clicked_at TIMESTAMP,
      unsubscribed_at TIMESTAMP
    )
  `;
  // One row per (campaign, member): two concurrent sends used to write every
  // recipient twice. Drop historical duplicates (keep the first row) before the
  // unique index, so the migration is idempotent on an existing database.
  await sql`
    DELETE FROM campaign_recipients a
    USING campaign_recipients b
    WHERE a.campaign_id = b.campaign_id AND a.user_id = b.user_id AND a.id > b.id
  `;
  await sql`
    CREATE UNIQUE INDEX IF NOT EXISTS uniq_campaign_recipients_campaign_user
    ON campaign_recipients(campaign_id, user_id)
  `;

  // User segments for targeting
  await sql`
    CREATE TABLE IF NOT EXISTS user_segments (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      description TEXT,
      filters JSONB NOT NULL DEFAULT '{}',
      user_count INTEGER DEFAULT 0,
      created_by VARCHAR(255),
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Event photos (multiple per event)
  await sql`
    CREATE TABLE IF NOT EXISTS event_photos (
      id SERIAL PRIMARY KEY,
      event_id INTEGER REFERENCES events(id) ON DELETE CASCADE,
      url TEXT NOT NULL,
      position INTEGER DEFAULT 0,
      is_cover BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Event check-ins
  await sql`
    CREATE TABLE IF NOT EXISTS event_checkins (
      id SERIAL PRIMARY KEY,
      event_id INTEGER REFERENCES events(id) ON DELETE CASCADE,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      checked_in_at TIMESTAMP DEFAULT NOW(),
      checked_in_by VARCHAR(255),
      UNIQUE(event_id, user_id)
    )
  `;

  // Photo moderation queue
  await sql`
    CREATE TABLE IF NOT EXISTS photo_moderation (
      id SERIAL PRIMARY KEY,
      photo_id INTEGER,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      photo_url TEXT NOT NULL,
      status VARCHAR(20) DEFAULT 'pending',
      reviewed_by VARCHAR(255),
      reviewed_at TIMESTAMP,
      rejection_reason TEXT,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Moderation logs (admin actions)
  await sql`
    CREATE TABLE IF NOT EXISTS moderation_logs (
      id SERIAL PRIMARY KEY,
      admin_email VARCHAR(255) NOT NULL,
      action VARCHAR(100) NOT NULL,
      target_type VARCHAR(50) NOT NULL,
      target_id INTEGER,
      details JSONB,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Email unsubscribes
  await sql`
    CREATE TABLE IF NOT EXISTS email_unsubscribes (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) UNIQUE NOT NULL,
      unsubscribed_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // ============ COUPLE MODE TABLES ============

  // Couple activities (feed)
  await sql`
    CREATE TABLE IF NOT EXISTS couple_activities (
      id SERIAL PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      description TEXT,
      category VARCHAR(50) NOT NULL,
      subcategory VARCHAR(50),
      image_url TEXT,
      images JSONB DEFAULT '[]',
      price_cents INTEGER,
      price_type VARCHAR(20) DEFAULT 'fixed',
      location VARCHAR(255),
      address TEXT,
      latitude DECIMAL(10, 8),
      longitude DECIMAL(11, 8),
      city VARCHAR(100),
      rating DECIMAL(2, 1),
      review_count INTEGER DEFAULT 0,
      is_kosher BOOLEAN DEFAULT false,
      is_partner BOOLEAN DEFAULT false,
      partner_name VARCHAR(255),
      discount_percent INTEGER,
      discount_code VARCHAR(50),
      booking_url TEXT,
      phone VARCHAR(50),
      website TEXT,
      duration_minutes INTEGER,
      available_days JSONB DEFAULT '["mon","tue","wed","thu","fri","sat","sun"]',
      tags JSONB DEFAULT '[]',
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Couple saved activities (bookmarks)
  await sql`
    CREATE TABLE IF NOT EXISTS couple_saved_activities (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER REFERENCES couples(id) ON DELETE CASCADE,
      activity_id INTEGER REFERENCES couple_activities(id) ON DELETE CASCADE,
      saved_at TIMESTAMP DEFAULT NOW(),
      notes TEXT,
      UNIQUE(couple_id, activity_id)
    )
  `;

  // Couple passed activities (swipe left)
  await sql`
    CREATE TABLE IF NOT EXISTS couple_passed_activities (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER REFERENCES couples(id) ON DELETE CASCADE,
      activity_id INTEGER REFERENCES couple_activities(id) ON DELETE CASCADE,
      passed_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(couple_id, activity_id)
    )
  `;

  // Couple bookings
  await sql`
    CREATE TABLE IF NOT EXISTS couple_bookings (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER REFERENCES couples(id) ON DELETE CASCADE,
      activity_id INTEGER REFERENCES couple_activities(id),
      event_id INTEGER,
      booking_date DATE,
      booking_time TIME,
      status VARCHAR(20) DEFAULT 'pending',
      confirmation_code VARCHAR(50),
      price_paid_cents INTEGER,
      notes TEXT,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Couple events (different from solo events)
  await sql`
    CREATE TABLE IF NOT EXISTS couple_events (
      id SERIAL PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      description TEXT,
      category VARCHAR(50),
      image_url TEXT,
      images JSONB DEFAULT '[]',
      event_date DATE NOT NULL,
      event_time TIME,
      end_time TIME,
      location VARCHAR(255),
      address TEXT,
      latitude DECIMAL(10, 8),
      longitude DECIMAL(11, 8),
      city VARCHAR(100),
      price_cents INTEGER,
      max_couples INTEGER,
      current_couples INTEGER DEFAULT 0,
      is_kosher BOOLEAN DEFAULT false,
      dress_code VARCHAR(100),
      what_included TEXT,
      organizer_name VARCHAR(255),
      organizer_contact VARCHAR(255),
      is_published BOOLEAN DEFAULT true,
      is_featured BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Couple event registrations
  await sql`
    CREATE TABLE IF NOT EXISTS couple_event_registrations (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER REFERENCES couples(id) ON DELETE CASCADE,
      event_id INTEGER REFERENCES couple_events(id) ON DELETE CASCADE,
      status VARCHAR(20) DEFAULT 'registered',
      paid BOOLEAN DEFAULT false,
      payment_date TIMESTAMP,
      registered_at TIMESTAMP DEFAULT NOW(),
      cancelled_at TIMESTAMP,
      UNIQUE(couple_id, event_id)
    )
  `;

  // Couple memories (photos, notes, milestones)
  await sql`
    CREATE TABLE IF NOT EXISTS couple_memories (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER REFERENCES couples(id) ON DELETE CASCADE,
      type VARCHAR(20) NOT NULL,
      title VARCHAR(255),
      content TEXT,
      image_url TEXT,
      memory_date DATE,
      location VARCHAR(255),
      tags JSONB DEFAULT '[]',
      is_favorite BOOLEAN DEFAULT false,
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Couple important dates (anniversaries, etc.)
  await sql`
    CREATE TABLE IF NOT EXISTS couple_dates (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER REFERENCES couples(id) ON DELETE CASCADE,
      title VARCHAR(255) NOT NULL,
      date DATE NOT NULL,
      type VARCHAR(50) NOT NULL,
      is_recurring BOOLEAN DEFAULT true,
      remind_days_before INTEGER DEFAULT 7,
      notes TEXT,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Couple bucket list
  await sql`
    CREATE TABLE IF NOT EXISTS couple_bucket_list (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER REFERENCES couples(id) ON DELETE CASCADE,
      title VARCHAR(255) NOT NULL,
      description TEXT,
      category VARCHAR(50),
      is_completed BOOLEAN DEFAULT false,
      completed_at TIMESTAMP,
      target_date DATE,
      priority INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;

  // Couple stats/achievements
  await sql`
    CREATE TABLE IF NOT EXISTS couple_achievements (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER REFERENCES couples(id) ON DELETE CASCADE,
      achievement_type VARCHAR(50) NOT NULL,
      achievement_name VARCHAR(100) NOT NULL,
      description TEXT,
      icon VARCHAR(50),
      unlocked_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(couple_id, achievement_type)
    )
  `;

  // ============ PERFORMANCE INDEXES ============
  // Hot paths: swipe exclusion, conversation messages, match lookups,
  // profile joins, event RSVPs, couple lookups, subscription lookups.
  await sql`CREATE INDEX IF NOT EXISTS idx_swipes_user_target ON swipes (user_id, target_user_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_swipes_target_user ON swipes (target_user_id, user_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages (conversation_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_matches_user1 ON matches (user1_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_matches_user2 ON matches (user2_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_profiles_user ON profiles (user_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_event_rsvps_event ON event_rsvps (event_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_couples_user1 ON couples (user1_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_couples_user2 ON couples (user2_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions (user_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker ON blocked_users (blocker_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked ON blocked_users (blocked_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_profile_prompts_user ON profile_prompts (user_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_boosts_user ON boosts (user_id)`;
  // Speeds up "currently boosted?" lookups and the active-boost prioritization.
  await sql`CREATE INDEX IF NOT EXISTS idx_boosts_expires_at ON boosts (expires_at)`;
  // Speeds up the daily-quota count in the selfie verification flow.
  await sql`CREATE INDEX IF NOT EXISTS idx_verification_attempts_user_created ON verification_attempts (user_id, created_at)`;

  console.log("Database initialized");

  // Sample data for development and tests only: in a real deployment the
  // community is made of real members and the couple catalogue is curated.
  if (isDevelopmentEnvironment()) {
    await seedFakeProfiles();
    await seedCoupleActivities();
    await seedCoupleEvents();
  }

  // Members who completed their profile before is_complete was derived.
  await backfillProfileCompleteness();
}

function generateVerificationToken() {
  return crypto.randomUUID().replace(/-/g, "") + crypto.randomUUID().replace(/-/g, "");
}

export async function requestReuploadAndRotateToken(waitlistId: number) {
  const verificationToken = generateVerificationToken();

  const result = await sql`
    UPDATE waitlist
    SET verification_status = 'pending',
        verification_token = ${verificationToken},
        verification_token_created_at = NOW(),
        verification_requested_at = NOW(),
        documents_submitted_at = NULL,
        verified_at = NULL
    WHERE id = ${waitlistId}
    RETURNING email, verification_token
  `;

  const row = result[0];
  if (!row) throw new Error("Waitlist not found");

  return { email: row.email as string, verificationToken: row.verification_token as string };
}

export interface WaitlistVerification {
  id: number;
  email: string;
  // The new emailable link token. Empty when `alreadyHandled`: nothing was
  // issued, and the live token of that member is never handed out.
  verificationToken: string;
  // True when the email already belongs to a member who is verified, verified+
  // or has submitted documents. Their status and link are left untouched, so an
  // anonymous caller cannot demote them or invalidate their link; the caller
  // must not send a verification e-mail.
  alreadyHandled: boolean;
}

// Public sign-up by email. Anyone can post any email, so a row past 'pending'
// is never rewritten: the SET clauses keep its status, token and dates.
export async function upsertWaitlistAndGetVerification(email: string): Promise<WaitlistVerification> {
  const verificationToken = generateVerificationToken();

  const result = await sql`
    INSERT INTO waitlist (email, token, status, confirmed_at, verification_token, verification_status, verification_requested_at, verification_token_created_at)
    VALUES (${email}, ${crypto.randomUUID()}, 'confirmed', NOW(), ${verificationToken}, 'pending', NOW(), NOW())
    ON CONFLICT (email)
    DO UPDATE SET
      verification_token = CASE WHEN waitlist.verification_status IN ('verified', 'verified_plus', 'submitted')
        THEN waitlist.verification_token ELSE EXCLUDED.verification_token END,
      verification_token_created_at = CASE WHEN waitlist.verification_status IN ('verified', 'verified_plus', 'submitted')
        THEN waitlist.verification_token_created_at ELSE NOW() END,
      verification_requested_at = CASE WHEN waitlist.verification_status IN ('verified', 'verified_plus', 'submitted')
        THEN waitlist.verification_requested_at ELSE NOW() END,
      verification_status = CASE WHEN waitlist.verification_status IN ('verified', 'verified_plus', 'submitted')
        THEN waitlist.verification_status ELSE 'pending' END
    RETURNING id, email, verification_token,
      COALESCE(verification_status IN ('verified', 'verified_plus', 'submitted'), false) AS already_handled
  `;

  const row = result[0];
  if (!row) throw new Error("Failed to upsert waitlist");

  const alreadyHandled = row.already_handled === true;
  return {
    id: row.id as number,
    email: row.email as string,
    verificationToken: alreadyHandled ? "" : (row.verification_token as string),
    alreadyHandled,
  };
}

export async function markVerificationSubmitted(waitlistId: number) {
  await sql`
    UPDATE waitlist
    SET verification_status = 'submitted', documents_submitted_at = NOW()
    WHERE id = ${waitlistId}
  `;
}

// A token older than `maxAgeDays` is as good as unknown.
export async function findWaitlistByVerificationToken(token: string, maxAgeDays: number) {
  const result = await sql`
    SELECT id, email, verification_status FROM waitlist
    WHERE verification_token = ${token}
      AND verification_token_created_at > NOW() - make_interval(days => ${maxAgeDays})
  `;
  return result.length ? (result[0] as { id: number; email: string; verification_status: string }) : null;
}

export async function listVerifiedProfiles() {
  const rows = await sql`
    SELECT w.id as waitlist_id, w.email, w.verification_status, w.verified_at, w.os,
           d.id as document_id, d.type, d.purged_at, d.mime_type, d.status as document_status, d.created_at
    FROM waitlist w
    LEFT JOIN documents d ON d.waitlist_id = w.id
    WHERE w.verification_status IN ('verified', 'verified_plus')
    ORDER BY w.verified_at DESC NULLS LAST, w.created_at DESC
  `;

  const grouped = new Map<number, any>();
  for (const row of rows) {
    const id = row.waitlist_id as number;
    if (!grouped.has(id)) {
      grouped.set(id, {
        waitlistId: id,
        email: row.email,
        verificationStatus: row.verification_status,
        verifiedAt: row.verified_at,
        os: row.os,
        documents: [],
      });
    }
    if (row.document_id) {
      grouped.get(id).documents.push({
        id: row.document_id,
        type: row.type,
        purged: row.purged_at !== null,
        mimeType: row.mime_type,
        status: row.document_status,
        createdAt: row.created_at,
      });
    }
  }

  return Array.from(grouped.values());
}

export async function listPendingSubmissions() {
  const rows = await sql`
    SELECT w.id as waitlist_id, w.email, w.verification_status, w.documents_submitted_at, w.os,
           d.id as document_id, d.type, d.purged_at, d.mime_type, d.status as document_status, d.created_at
    FROM waitlist w
    LEFT JOIN documents d ON d.waitlist_id = w.id
    WHERE w.verification_status IN ('submitted', 'pending')
    ORDER BY w.documents_submitted_at DESC NULLS LAST, w.created_at DESC
  `;

  const grouped = new Map<number, any>();
  for (const row of rows) {
    const id = row.waitlist_id as number;
    if (!grouped.has(id)) {
      grouped.set(id, {
        waitlistId: id,
        email: row.email,
        verificationStatus: row.verification_status,
        submittedAt: row.documents_submitted_at,
        os: row.os,
        documents: [],
      });
    }
    if (row.document_id) {
      grouped.get(id).documents.push({
        id: row.document_id,
        type: row.type,
        purged: row.purged_at !== null,
        mimeType: row.mime_type,
        status: row.document_status,
        createdAt: row.created_at,
      });
    }
  }

  return Array.from(grouped.values());
}

export async function getWaitlistEmailById(waitlistId: number) {
  const rows = await sql`
    SELECT email FROM waitlist WHERE id = ${waitlistId}
  `;
  const row = rows[0];
  return row ? (row.email as string) : null;
}

export async function setWaitlistOS(waitlistId: number, os: string) {
  await sql`
    UPDATE waitlist SET os = ${os} WHERE id = ${waitlistId}
  `;
}

export async function setWaitlistVerificationStatus(waitlistId: number, status: string) {
  const verifiedAt = status === 'verified' || status === 'verified_plus' ? sql`NOW()` : sql`NULL`;
  const submittedAt = status === 'submitted' ? sql`NOW()` : sql`documents_submitted_at`;
  const resetSubmitted = status === 'pending' ? sql`NULL` : submittedAt;

  await sql`
    UPDATE waitlist
    SET verification_status = ${status},
        verified_at = ${verifiedAt},
        documents_submitted_at = ${resetSubmitted}
    WHERE id = ${waitlistId}
  `;
}


export async function confirmEmail(token: string) {
  const result = await sql`
    UPDATE waitlist
    SET status = 'confirmed', confirmed_at = NOW()
    WHERE token = ${token} AND status = 'pending'
    RETURNING email
  `;
  return result.length > 0 ? result[0] : null;
}

export async function getConfirmedCount() {
  const result = await sql`
    SELECT COUNT(*) as count FROM waitlist WHERE status = 'confirmed'
  `;
  const row = result[0];
  return row ? parseInt(row.count) : 0;
}

export async function getTotalCount() {
  const result = await sql`
    SELECT COUNT(*) as count FROM waitlist WHERE status = 'confirmed'
  `;
  const row = result[0];
  return row ? parseInt(row.count) : 0;
}

// ============ USER AUTH FUNCTIONS ============

export interface User {
  id: number;
  email: string;
  name: string | null;
  picture: string | null;
  provider: "google" | "apple";
  provider_id: string;
  created_at: Date;
  is_active: boolean;
}

export async function findUserByProviderId(provider: string, providerId: string): Promise<User | null> {
  const result = await sql`
    SELECT * FROM users WHERE provider = ${provider} AND provider_id = ${providerId}
  `;
  return result.length ? (result[0] as User) : null;
}

export async function findUserByEmail(email: string): Promise<User | null> {
  const result = await sql`
    SELECT * FROM users WHERE email = ${email}
  `;
  return result.length ? (result[0] as User) : null;
}

export async function findUserById(id: number): Promise<User | null> {
  const result = await sql`
    SELECT * FROM users WHERE id = ${id}
  `;
  return result.length ? (result[0] as User) : null;
}

export async function createUser(params: {
  email: string;
  name?: string;
  picture?: string;
  provider: "google" | "apple";
  providerId: string;
}): Promise<User> {
  const result = await sql`
    INSERT INTO users (email, name, picture, provider, provider_id)
    VALUES (${params.email}, ${params.name ?? null}, ${params.picture ?? null}, ${params.provider}, ${params.providerId})
    RETURNING *
  `;
  return result[0] as User;
}

export async function upsertUser(params: {
  email: string;
  name?: string;
  picture?: string;
  provider: "google" | "apple";
  providerId: string;
}): Promise<{ user: User; isNew: boolean }> {
  // Try to find existing user by provider ID
  let user = await findUserByProviderId(params.provider, params.providerId);

  if (user) {
    // Update existing user
    const result = await sql`
      UPDATE users
      SET name = COALESCE(${params.name ?? null}, name),
          picture = COALESCE(${params.picture ?? null}, picture),
          last_login_at = NOW(),
          updated_at = NOW()
      WHERE id = ${user.id}
      RETURNING *
    `;
    return { user: result[0] as User, isNew: false };
  }

  // Create new user
  user = await createUser(params);
  return { user, isNew: true };
}

export async function updateUserLastLogin(userId: number): Promise<void> {
  await sql`
    UPDATE users SET last_login_at = NOW() WHERE id = ${userId}
  `;
}

export async function getUserProfile(userId: number) {
  const result = await sql`
    SELECT * FROM profiles WHERE user_id = ${userId}
  `;
  return result.length ? result[0] : null;
}

// The member's own photos as the API exposes them (signed URLs, primary
// first), for GET /api/auth/me: the app reads its profile from there.
export async function getOwnPhotoUrls(userId: number): Promise<string[]> {
  const photos = await sql<{ id: number; url: string }[]>`
    SELECT id, url FROM profile_photos
    WHERE user_id = ${userId}
    ORDER BY is_primary DESC, position ASC, id ASC
  `;
  return publicPhotoUrls(photos);
}

// `includePrivate` is for the member's OWN profile only: email and the account
// name (possibly a legal name) are never returned about someone else.
export async function getFullProfile(userId: number, includePrivate = false) {
  // Get profile with user info
  const result = await sql`
    SELECT
      p.id,
      p.user_id,
      p.display_name,
      DATE_PART('year', AGE(p.birthdate)) as age,
      p.gender,
      p.bio,
      p.location,
      p.denomination,
      p.kashrut_level,
      p.shabbat_observance,
      p.looking_for,
      ${badgeColumns(sql)},
      p.verification_level,
      u.picture,
      ${primaryPhotoColumns(sql)},
      u.name,
      u.email
    FROM profiles p
    JOIN users u ON u.id = p.user_id
    WHERE p.user_id = ${userId}
  `;

  if (result.length === 0) return null;

  const { name, email, ...shared } = withPublicPicture(result[0] as any);
  const profile = includePrivate ? { ...shared, name, email } : shared;

  // Get photos (signed URLs only; see features/media)
  const photos = await sql`
    SELECT id, url, position FROM profile_photos
    WHERE user_id = ${userId}
    ORDER BY position ASC
  `;
  const photoUrls = publicPhotoUrls(photos as any[]);

  return {
    ...profile,
    photos: photoUrls.length > 0 ? photoUrls : (profile.picture ? [profile.picture] : []),
  };
}

// Whether `viewerId` may see the profile of `targetId`: the profile is
// complete, the account is active and neither member blocked the other. Every
// "no" looks the same to the caller (a missing profile), so that a block, a ban
// or an unfinished profile cannot be told apart from an unknown id.
export async function isProfileVisibleTo(viewerId: number, targetId: number): Promise<boolean> {
  const rows = await sql`
    SELECT 1
    FROM profiles p
    JOIN users u ON u.id = p.user_id
    WHERE p.user_id = ${targetId}
      AND p.is_complete = true
      AND u.is_active = true
      AND NOT EXISTS (
        SELECT 1 FROM blocked_users b
        WHERE (b.blocker_id = ${viewerId} AND b.blocked_id = ${targetId})
           OR (b.blocker_id = ${targetId} AND b.blocked_id = ${viewerId})
      )
  `;
  return rows.length > 0;
}

export async function upsertProfile(userId: number, params: {
  displayName?: string;
  birthdate?: string;
  gender?: string;
  bio?: string;
  location?: string;
  latitude?: number;
  longitude?: number;
  denomination?: string;
  kashrutLevel?: string;
  shabbatObservance?: string;
  lookingFor?: string;
  ageMin?: number;
  ageMax?: number;
  distanceMax?: number;
  relationshipIntention?: string;
}) {
  // Callers pass coordinates that the media location service already fuzzed.
  const hasPosition = params.latitude !== undefined && params.longitude !== undefined;
  const result = await sql`
    INSERT INTO profiles (user_id, display_name, birthdate, gender, bio, location, latitude, longitude, location_fuzzed, denomination, kashrut_level, shabbat_observance, looking_for, age_min, age_max, distance_max, relationship_intention)
    VALUES (
      ${userId},
      ${params.displayName ?? null},
      ${params.birthdate ?? null},
      ${params.gender ?? null},
      ${params.bio ?? null},
      ${params.location ?? null},
      ${params.latitude ?? null},
      ${params.longitude ?? null},
      ${hasPosition},
      ${params.denomination ?? null},
      ${params.kashrutLevel ?? null},
      ${params.shabbatObservance ?? null},
      ${params.lookingFor ?? null},
      ${params.ageMin ?? 18},
      ${params.ageMax ?? 99},
      ${params.distanceMax ?? 100},
      ${params.relationshipIntention ?? null}
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
      display_name = COALESCE(${params.displayName ?? null}, profiles.display_name),
      -- once read from a verified document (level 2), the birthdate is locked
      birthdate = CASE WHEN profiles.birthdate_locked THEN profiles.birthdate
                       ELSE COALESCE(${params.birthdate ?? null}, profiles.birthdate) END,
      gender = COALESCE(${params.gender ?? null}, profiles.gender),
      bio = COALESCE(${params.bio ?? null}, profiles.bio),
      location = COALESCE(${params.location ?? null}, profiles.location),
      latitude = COALESCE(${params.latitude ?? null}, profiles.latitude),
      longitude = COALESCE(${params.longitude ?? null}, profiles.longitude),
      location_fuzzed = profiles.location_fuzzed OR ${hasPosition},
      denomination = COALESCE(${params.denomination ?? null}, profiles.denomination),
      kashrut_level = COALESCE(${params.kashrutLevel ?? null}, profiles.kashrut_level),
      shabbat_observance = COALESCE(${params.shabbatObservance ?? null}, profiles.shabbat_observance),
      looking_for = COALESCE(${params.lookingFor ?? null}, profiles.looking_for),
      age_min = COALESCE(${params.ageMin ?? null}, profiles.age_min),
      age_max = COALESCE(${params.ageMax ?? null}, profiles.age_max),
      distance_max = COALESCE(${params.distanceMax ?? null}, profiles.distance_max),
      relationship_intention = COALESCE(${params.relationshipIntention ?? null}, profiles.relationship_intention),
      updated_at = NOW()
    RETURNING *
  `;
  const stored = result[0];
  return stored === undefined ? stored : await syncProfileCompleteness(stored);
}

// `profiles.is_complete` is derived, never sent by the client: it follows
// isProfileComplete (features/profile/domain) applied to the stored row.
async function syncProfileCompleteness<Row extends Record<string, unknown>>(row: Row): Promise<Row> {
  const complete = isProfileComplete(row);
  if (row["is_complete"] === complete) return row;
  await sql`UPDATE profiles SET is_complete = ${complete} WHERE user_id = ${Number(row["user_id"])}`;
  return { ...row, is_complete: complete };
}

/**
 * Idempotent: flags the profiles that already satisfy the rule but were never
 * flagged (nothing used to set `is_complete`). Never unflags anyone.
 */
export async function backfillProfileCompleteness(): Promise<number> {
  const rows = await sql<{ user_id: number; display_name: string | null; birthdate: Date | null; gender: string | null; looking_for: string | null }[]>`
    SELECT user_id, display_name, birthdate, gender, looking_for
    FROM profiles WHERE is_complete IS NOT TRUE
  `;
  const ids = rows.filter((row) => isProfileComplete(row)).map((row) => row.user_id);
  if (ids.length === 0) return 0;
  await sql`UPDATE profiles SET is_complete = true WHERE user_id IN ${sql(ids)} AND is_complete IS NOT TRUE`;
  return ids.length;
}

// ============ DISCOVER & SWIPES ============

// ============ BOOST ============

export interface BoostRecord {
  id: number;
  user_id: number;
  activated_at: Date;
  expires_at: Date;
  created_at: Date;
}

/**
 * Activate a boost for a user: inserts a boost row expiring in
 * `durationMinutes` (default 30). Returns the created record.
 */
export async function activateBoost(
  userId: number,
  durationMinutes = 30,
): Promise<BoostRecord> {
  const rows = await sql<BoostRecord[]>`
    INSERT INTO boosts (user_id, activated_at, expires_at)
    VALUES (
      ${userId},
      NOW(),
      NOW() + (${durationMinutes} * INTERVAL '1 minute')
    )
    RETURNING id, user_id, activated_at, expires_at, created_at
  `;
  return rows[0]!;
}

/**
 * Return the user's currently-active boost (expires_at in the future),
 * or null if none is active. Picks the one expiring latest.
 */
export async function getActiveBoost(userId: number): Promise<BoostRecord | null> {
  const rows = await sql<BoostRecord[]>`
    SELECT id, user_id, activated_at, expires_at, created_at
    FROM boosts
    WHERE user_id = ${userId}
      AND expires_at > NOW()
    ORDER BY expires_at DESC
    LIMIT 1
  `;
  return rows[0] ?? null;
}

/**
 * Count how many boosts the user activated today (server-local calendar day).
 * Useful for quota enforcement / display.
 */
export async function getBoostsUsedToday(userId: number): Promise<number> {
  const rows = await sql<{ count: string }[]>`
    SELECT COUNT(*)::int AS count
    FROM boosts
    WHERE user_id = ${userId}
      AND activated_at >= DATE_TRUNC('day', NOW())
  `;
  return Number(rows[0]?.count ?? 0);
}

/**
 * Set of user IDs that currently have an active boost.
 * Used to prioritize boosted profiles in the discover feed.
 */
export async function getActiveBoostedUserIds(): Promise<Set<number>> {
  const rows = await sql<{ user_id: number }[]>`
    SELECT DISTINCT user_id
    FROM boosts
    WHERE expires_at > NOW()
  `;
  return new Set(rows.map((r) => r.user_id));
}

// ============ LEGACY GESTURE VERIFICATION (US-TS-03) ============
//
// Only `startVerification` survives, for app versions that still call
// POST /api/verification/start. It verifies nobody: the real check lives in
// src/features/verification (live selfie + face matching).

/** Maximum selfie-verification attempts a user may make per calendar day. */
export const VERIFICATION_DAILY_LIMIT = 3;

/** Gestures a user may be asked to perform. IDs must match the mobile client. */
export const VERIFICATION_GESTURES = [
  "hand_up",
  "smile",
  "thumbs_up",
] as const;

export type VerificationGestureId = (typeof VERIFICATION_GESTURES)[number];

export interface StartVerificationResult {
  ok: boolean;
  gestureId?: VerificationGestureId;
  attemptId?: number;
  /** ISO timestamp of the next allowed attempt when the quota is exhausted. */
  nextAttemptTime?: string;
  message?: string;
}

/** Count verification attempts made by the user during the current server day. */
async function countVerificationAttemptsToday(userId: number): Promise<number> {
  const rows = await sql<{ count: string }[]>`
    SELECT COUNT(*)::int AS count
    FROM verification_attempts
    WHERE user_id = ${userId}
      AND created_at >= DATE_TRUNC('day', NOW())
  `;
  return Number(rows[0]?.count ?? 0);
}

/** ISO timestamp of the next midnight (start of tomorrow), server-local. */
async function nextMidnightIso(): Promise<string> {
  const rows = await sql<{ next_midnight: Date }[]>`
    SELECT (DATE_TRUNC('day', NOW()) + INTERVAL '1 day') AS next_midnight
  `;
  return (rows[0]?.next_midnight ?? new Date()).toISOString();
}

/**
 * Start a selfie verification: enforce the per-day quota, pick a random
 * gesture, and record a `pending` attempt. Returns the gesture + attempt id,
 * or an unsuccessful result carrying `nextAttemptTime` when the quota is hit.
 * The quota is enforced HERE (server-side), not trusted from the client.
 */
export async function startVerification(
  userId: number,
): Promise<StartVerificationResult> {
  const attemptsToday = await countVerificationAttemptsToday(userId);
  if (attemptsToday >= VERIFICATION_DAILY_LIMIT) {
    return {
      ok: false,
      nextAttemptTime: await nextMidnightIso(),
      message: "Limite de tentatives atteinte (3/jour). Réessayez demain.",
    };
  }

  const gestureId =
    VERIFICATION_GESTURES[
      Math.floor(Math.random() * VERIFICATION_GESTURES.length)
    ]!;

  const rows = await sql<{ id: number }[]>`
    INSERT INTO verification_attempts (user_id, gesture_id, status)
    VALUES (${userId}, ${gestureId}, 'pending')
    RETURNING id
  `;

  return { ok: true, gestureId, attemptId: rows[0]!.id };
}

/** The caller's own gender / looking_for (null when there is no profile row). */
export async function getProfilePreferences(userId: number): Promise<{
  gender: string | null;
  looking_for: string | null;
} | null> {
  const rows = await sql<{ gender: string | null; looking_for: string | null }[]>`
    SELECT gender, looking_for FROM profiles WHERE user_id = ${userId}
  `;
  return rows[0] ?? null;
}

export async function getDiscoverProfiles(userId: number, limit = 20, offset = 0) {
  // Fetch candidate profiles filtered against the CALLER's own preferences.
  // Criteria are read directly from the caller's profile row (CTE `me`) so
  // the public signature stays (userId, limit, offset).
  //
  // Filtering rules:
  //  - gender/orientation: bidirectional and STRICT. The candidate's gender must
  //    match the caller's `looking_for`, AND the candidate's `looking_for` must
  //    match the caller's gender (legacy 'all'/'any'/'everyone' on the candidate
  //    side is open). A caller without gender / looking_for never reaches this
  //    query: the route answers 409 profile_incomplete first.
  //  - the other criteria are null-tolerant: a missing one never excludes.
  //  - age: candidate age within the caller's [age_min, age_max].
  //  - distance: when both parties have lat/long and the caller has distance_max,
  //    haversine distance (km) must be <= distance_max.
  //
  // Ordering: religious-compatibility score first (denomination / kashrut /
  // shabbat matches with the caller weighted), then recency.
  const profiles = await sql`
    WITH me AS (
      SELECT gender, looking_for, age_min, age_max, distance_max,
             latitude, longitude, denomination, kashrut_level, shabbat_observance
      FROM profiles WHERE user_id = ${userId}
    )
    SELECT
      p.id,
      p.user_id,
      p.display_name,
      DATE_PART('year', AGE(p.birthdate)) as age,
      p.gender,
      p.bio,
      p.location,
      p.denomination,
      p.kashrut_level,
      p.shabbat_observance,
      ${badgeColumns(sql)},
      p.verification_level,
      u.picture,
      ${primaryPhotoColumns(sql)}
    FROM profiles p
    JOIN users u ON u.id = p.user_id
    CROSS JOIN me
    WHERE p.user_id != ${userId}
      AND u.is_active = true
      AND p.is_complete = true
      -- the App Store review account is never offered to anybody
      AND u.provider <> 'review'
      AND p.user_id NOT IN (
        SELECT target_user_id FROM swipes WHERE user_id = ${userId}
      )
      -- exclude users blocked in either direction
      AND p.user_id NOT IN (
        SELECT blocked_id FROM blocked_users WHERE blocker_id = ${userId}
        UNION
        SELECT blocker_id FROM blocked_users WHERE blocked_id = ${userId}
      )
      -- caller wants candidate's gender. Strict: the route refuses callers who
      -- have not set looking_for (409 profile_incomplete), and a candidate with
      -- no gender can never match a stated preference.
      AND LOWER(p.gender) = LOWER(me.looking_for)
      -- candidate wants caller's gender (legacy open values still accepted)
      AND (
        LOWER(p.looking_for) IN ('all', 'any', 'everyone', 'both')
        OR LOWER(p.looking_for) = LOWER(me.gender)
      )
      -- candidate age within caller's range (skip when birthdate unknown)
      AND (
        p.birthdate IS NULL
        OR (
          DATE_PART('year', AGE(p.birthdate)) >= COALESCE(me.age_min, 18)
          AND DATE_PART('year', AGE(p.birthdate)) <= COALESCE(me.age_max, 99)
        )
      )
      -- distance filter (only when both have coords and caller set distance_max)
      AND (
        me.distance_max IS NULL
        OR me.latitude IS NULL OR me.longitude IS NULL
        OR p.latitude IS NULL OR p.longitude IS NULL
        OR (
          6371 * ACOS(
            LEAST(1.0, GREATEST(-1.0,
              COS(RADIANS(me.latitude)) * COS(RADIANS(p.latitude))
              * COS(RADIANS(p.longitude) - RADIANS(me.longitude))
              + SIN(RADIANS(me.latitude)) * SIN(RADIANS(p.latitude))
            ))
          ) <= me.distance_max
        )
      )
    ORDER BY
      -- boosted candidates float to the top of the feed
      (
        CASE WHEN EXISTS (
          SELECT 1 FROM boosts b
          WHERE b.user_id = p.user_id AND b.expires_at > NOW()
        ) THEN 1 ELSE 0 END
      ) DESC,
      (
        CASE WHEN me.denomination IS NOT NULL AND p.denomination = me.denomination THEN 3 ELSE 0 END
        + CASE WHEN me.kashrut_level IS NOT NULL AND p.kashrut_level = me.kashrut_level THEN 2 ELSE 0 END
        + CASE WHEN me.shabbat_observance IS NOT NULL AND p.shabbat_observance = me.shabbat_observance THEN 2 ELSE 0 END
      ) DESC,
      p.created_at DESC,
      p.user_id DESC
    LIMIT ${limit}
    OFFSET ${offset}
  `;

  // Get photos for each profile
  const userIds = profiles.map((p: any) => p.user_id);
  const photos = userIds.length > 0 ? await sql`
    SELECT id, user_id, url, position FROM profile_photos
    WHERE user_id IN ${sql(userIds)}
    ORDER BY position ASC
  ` : [];

  const photoMap = new Map<number, Array<{ id: number; url: string }>>();
  for (const photo of photos as any[]) {
    if (!photoMap.has(photo.user_id)) {
      photoMap.set(photo.user_id, []);
    }
    photoMap.get(photo.user_id)!.push({ id: photo.id, url: photo.url });
  }

  return profiles.map((raw: any) => {
    const p = withPublicPicture(raw);
    const urls = publicPhotoUrls(photoMap.get(raw.user_id) ?? []);
    return { ...p, photos: urls.length > 0 ? urls : (p.picture ? [p.picture] : []) };
  });
}

// The action of the swipe a member already recorded on a target, if any.
export async function getSwipeAction(userId: number, targetUserId: number): Promise<string | null> {
  const rows = await sql<{ action: string }[]>`
    SELECT action FROM swipes WHERE user_id = ${userId} AND target_user_id = ${targetUserId}
  `;
  return rows[0]?.action ?? null;
}

// Whether `userId` may swipe on `targetUserId`: another member whose account
// exists and is active, with no block in either direction. A refusal never says
// which of these held.
export async function canSwipeOn(userId: number, targetUserId: number): Promise<boolean> {
  if (userId === targetUserId) return false;
  const rows = await sql`
    SELECT 1 FROM users u
    WHERE u.id = ${targetUserId}
      AND u.is_active = true
      AND NOT EXISTS (
        SELECT 1 FROM blocked_users b
        WHERE (b.blocker_id = ${userId} AND b.blocked_id = ${targetUserId})
           OR (b.blocker_id = ${targetUserId} AND b.blocked_id = ${userId})
      )
  `;
  return rows.length > 0;
}

export async function recordSwipe(userId: number, targetUserId: number, action: string) {
  // Record the swipe
  await sql`
    INSERT INTO swipes (user_id, target_user_id, action)
    VALUES (${userId}, ${targetUserId}, ${action})
    ON CONFLICT (user_id, target_user_id)
    DO UPDATE SET action = ${action}, created_at = NOW()
  `;

  // Check for match if it's a like or super_like
  if (action === 'like' || action === 'super_like') {
    const mutualLike = await sql`
      SELECT id FROM swipes
      WHERE user_id = ${targetUserId}
        AND target_user_id = ${userId}
        AND action IN ('like', 'super_like')
    `;

    if (mutualLike.length > 0) {
      // Create match (order user IDs to prevent duplicates)
      const [user1, user2] = userId < targetUserId ? [userId, targetUserId] : [targetUserId, userId];
      const matchResult = await sql`
        INSERT INTO matches (user1_id, user2_id)
        VALUES (${user1}, ${user2})
        ON CONFLICT (user1_id, user2_id) DO NOTHING
        RETURNING id
      `;

      // Create conversation for the match
      if (matchResult.length > 0) {
        const matchId = (matchResult[0] as any).id;
        await createConversationForMatch(matchId, user1, user2);
      }

      return { match: true, targetUserId };
    }
  }

  return { match: false };
}

export async function getMatches(userId: number) {
  const matches = await sql`
    SELECT
      m.id as match_id,
      m.created_at as matched_at,
      c.id as conversation_id,
      CASE
        WHEN m.user1_id = ${userId} THEN m.user2_id
        ELSE m.user1_id
      END as other_user_id
    FROM matches m
    LEFT JOIN conversations c ON c.match_id = m.id
    WHERE (m.user1_id = ${userId} OR m.user2_id = ${userId})
      -- exclude matches with a user blocked in either direction
      AND (CASE WHEN m.user1_id = ${userId} THEN m.user2_id ELSE m.user1_id END) NOT IN (
        SELECT blocked_id FROM blocked_users WHERE blocker_id = ${userId}
        UNION
        SELECT blocker_id FROM blocked_users WHERE blocked_id = ${userId}
      )
    ORDER BY m.created_at DESC
  `;

  if (matches.length === 0) return [];

  const otherUserIds = matches.map((m: any) => m.other_user_id);

  const profiles = await sql`
    SELECT
      p.user_id,
      p.display_name,
      DATE_PART('year', AGE(p.birthdate)) as age,
      p.location,
      ${badgeColumns(sql)},
      u.picture,
      ${primaryPhotoColumns(sql)}
    FROM profiles p
    JOIN users u ON u.id = p.user_id
    WHERE p.user_id IN ${sql(otherUserIds)}
  `;

  const profileMap = new Map<number, any>();
  for (const p of profiles as any[]) {
    profileMap.set(p.user_id, withPublicPicture(p));
  }

  return matches.map((m: any) => ({
    matchId: m.match_id,
    matchedAt: m.matched_at,
    conversationId: m.conversation_id,
    profile: profileMap.get(m.other_user_id),
  }));
}

// ============ RECEIVED LIKES ============

// Profiles of users who liked/super-liked the caller but with whom no match
// exists yet, excluding users blocked in either direction. Shape mirrors
// getMatches profile rows plus liked_at.
export async function getReceivedLikes(userId: number): Promise<Array<{
  user_id: number;
  display_name: string | null;
  age: number | null;
  location: string | null;
  is_verified: boolean | null;
  picture: string | null;
  liked_at: Date;
}>> {
  const rows = await sql`
    SELECT
      s.user_id AS user_id,
      p.display_name,
      DATE_PART('year', AGE(p.birthdate)) AS age,
      p.location,
      ${badgeColumns(sql)},
      u.picture,
      ${primaryPhotoColumns(sql)},
      s.created_at AS liked_at
    FROM swipes s
    JOIN users u ON u.id = s.user_id
    LEFT JOIN profiles p ON p.user_id = s.user_id
    WHERE s.target_user_id = ${userId}
      AND u.is_active = true
      AND s.action IN ('like', 'super_like')
      -- not already matched
      AND NOT EXISTS (
        SELECT 1 FROM matches m
        WHERE (m.user1_id = ${userId} AND m.user2_id = s.user_id)
           OR (m.user2_id = ${userId} AND m.user1_id = s.user_id)
      )
      -- exclude users blocked in either direction
      AND s.user_id NOT IN (
        SELECT blocked_id FROM blocked_users WHERE blocker_id = ${userId}
        UNION
        SELECT blocker_id FROM blocked_users WHERE blocked_id = ${userId}
      )
    ORDER BY s.created_at DESC
  `;
  return rows.map((row) => withPublicPicture(row as any)) as unknown as Array<{
    user_id: number;
    display_name: string | null;
    age: number | null;
    location: string | null;
    is_verified: boolean | null;
    picture: string | null;
    liked_at: Date;
  }>;
}

export async function getReceivedLikesCount(userId: number): Promise<number> {
  const rows = await sql`
    SELECT COUNT(*) AS count
    FROM swipes s
    JOIN users u ON u.id = s.user_id
    WHERE s.target_user_id = ${userId}
      AND u.is_active = true
      AND s.action IN ('like', 'super_like')
      AND NOT EXISTS (
        SELECT 1 FROM matches m
        WHERE (m.user1_id = ${userId} AND m.user2_id = s.user_id)
           OR (m.user2_id = ${userId} AND m.user1_id = s.user_id)
      )
      AND s.user_id NOT IN (
        SELECT blocked_id FROM blocked_users WHERE blocker_id = ${userId}
        UNION
        SELECT blocker_id FROM blocked_users WHERE blocked_id = ${userId}
      )
  `;
  const row = rows[0] as { count: string } | undefined;
  return row ? parseInt(row.count) : 0;
}

// ============ PROFILE PROMPTS ============

export interface ProfilePromptRow {
  id: number;
  prompt_id: string;
  answer: string;
  position: number;
}

export const PROMPT_CATALOG: ReadonlyArray<{ id: string; text: string; category: string }> = [
  // Personnalité
  { id: 'perfect_sunday', text: 'Mon dimanche parfait...', category: 'personality' },
  { id: 'fun_fact', text: 'Un fait surprenant sur moi...', category: 'personality' },
  { id: 'life_goal', text: 'Un de mes objectifs dans la vie...', category: 'personality' },
  { id: 'pet_peeve', text: "Ce qui m'énerve le plus...", category: 'personality' },
  { id: 'proud_of', text: 'Je suis fier(e) de...', category: 'personality' },
  { id: 'looking_for', text: 'Je cherche quelqu\'un qui...', category: 'personality' },
  // Lifestyle
  { id: 'ideal_vacation', text: 'Mes vacances idéales...', category: 'lifestyle' },
  { id: 'favorite_food', text: 'Mon plat préféré...', category: 'lifestyle' },
  { id: 'hidden_talent', text: 'Mon talent caché...', category: 'lifestyle' },
  { id: 'binge_watching', text: 'En ce moment je regarde...', category: 'lifestyle' },
  // Judaïsme
  { id: 'shabbat_ideal', text: 'Mon Shabbat idéal...', category: 'jewish' },
  { id: 'family_tradition', text: "Une tradition familiale que j'adore...", category: 'jewish' },
  { id: 'favorite_holiday', text: 'Ma fête juive préférée...', category: 'jewish' },
  { id: 'friday_night', text: 'Le vendredi soir chez moi...', category: 'jewish' },
  { id: 'israel_memory', text: 'Mon meilleur souvenir en Israël...', category: 'jewish' },
  { id: 'jewish_value', text: 'Une valeur juive qui me guide...', category: 'jewish' },
  // Conversation starters
  { id: 'debate_me', text: 'Débats moi sur...', category: 'conversation' },
  { id: 'teach_me', text: 'Apprends-moi quelque chose sur...', category: 'conversation' },
  { id: 'together_we_could', text: 'Ensemble on pourrait...', category: 'conversation' },
  { id: 'first_date', text: 'Premier date idéal...', category: 'conversation' },
];

const PROMPT_TEXT_BY_ID = new Map(PROMPT_CATALOG.map((p) => [p.id, p.text]));

export function getPromptText(promptId: string): string {
  return PROMPT_TEXT_BY_ID.get(promptId) ?? '';
}

const MAX_PROFILE_PROMPTS = 3;
// First key of the advisory lock that serialises a member's prompt additions.
const PROFILE_PROMPTS_LOCK_NAMESPACE = 7201;

export class ProfilePromptLimitError extends Error {
  constructor() {
    super('Maximum of 3 prompts reached');
    this.name = 'ProfilePromptLimitError';
  }
}

export async function getProfilePrompts(userId: number): Promise<ProfilePromptRow[]> {
  const rows = await sql`
    SELECT id, prompt_id, answer, position
    FROM profile_prompts
    WHERE user_id = ${userId}
    ORDER BY position ASC, id ASC
  `;
  return rows as unknown as ProfilePromptRow[];
}

export async function addProfilePrompt(
  userId: number,
  promptId: string,
  answer: string,
  position: number,
): Promise<ProfilePromptRow> {
  // Counting then inserting would let simultaneous requests all see "2" and
  // each add a third prompt: the whole check runs under a lock held per member
  // until the transaction ends.
  return sql.begin(async (transaction) => {
    const tx = transaction as unknown as typeof sql;
    await tx`SELECT pg_advisory_xact_lock(${PROFILE_PROMPTS_LOCK_NAMESPACE}, ${userId})`;
    const countRows = await tx`
      SELECT COUNT(*) AS count FROM profile_prompts WHERE user_id = ${userId}
    `;
    const existing = parseInt((countRows[0] as { count: string }).count);
    if (existing >= MAX_PROFILE_PROMPTS) {
      throw new ProfilePromptLimitError();
    }

    const rows = await tx`
      INSERT INTO profile_prompts (user_id, prompt_id, answer, position)
      VALUES (${userId}, ${promptId}, ${answer}, ${position})
      RETURNING id, prompt_id, answer, position
    `;
    return rows[0] as unknown as ProfilePromptRow;
  });
}

export async function updateProfilePrompt(
  userId: number,
  promptId: number,
  answer: string,
): Promise<ProfilePromptRow | null> {
  const rows = await sql`
    UPDATE profile_prompts
    SET answer = ${answer}, updated_at = NOW()
    WHERE id = ${promptId} AND user_id = ${userId}
    RETURNING id, prompt_id, answer, position
  `;
  return rows.length ? (rows[0] as unknown as ProfilePromptRow) : null;
}

export async function deleteProfilePrompt(userId: number, promptId: number): Promise<boolean> {
  const rows = await sql`
    DELETE FROM profile_prompts
    WHERE id = ${promptId} AND user_id = ${userId}
    RETURNING id
  `;
  return rows.length > 0;
}

// ============ TEST PROFILES (TestFlight phase) ============

// The test profiles and the administrators' sample conversations
// (features/fixtures/test-profiles), and the "coming soon" fake events
// (features/fixtures/test-events), written at start-up when
// SEED_TEST_PROFILES=true (src/index.ts, once every schema is in place: they
// touch the media and verification columns): the hosting has no shell to run
// scripts/seed-test-profiles.ts against its database. Idempotent, so every
// restart is harmless; scripts/purge-seed-data.ts removes all of it.
export async function seedTestProfilesIfRequested(flag = process.env.SEED_TEST_PROFILES): Promise<void> {
  if (flag !== "true") return;
  // The review account exists before the seed, which gives it its conversations.
  const review = readReviewLoginConfig(process.env);
  if (review !== null) await ensureReviewAccount(sql, review.username);
  const plan = await applyTestProfiles(sql);
  console.log(`Test profiles ready: ${plan.members.length} member(s), ${plan.admins.length} administrator account(s)`);
  const events = await applyTestEvents(sql);
  console.log(`Test events ready: ${events.length} coming soon event(s)`);
}

// ============ SEED FAKE PROFILES ============

export async function seedFakeProfiles(force = false) {
  // Check if we already have fake profiles
  const existingCount = await sql`SELECT COUNT(*) as count FROM users WHERE provider = 'seed'`;
  if (!force && parseInt((existingCount[0] as any).count) > 0) {
    console.log("Seed profiles already exist, skipping...");
    return;
  }

  console.log("Seeding 20 fake profiles...");

  const femaleProfiles = [
    { name: "Sarah Cohen", age: 25, city: "Paris", bio: "Amoureuse de la vie, de voyages et de bonne cuisine. J'adore les soirées Shabbat en famille.", denomination: "Modern Orthodox", kashrut: "Kosher", shabbat: "Observant" },
    { name: "Rachel Levy", age: 27, city: "Lyon", bio: "Passionnée de musique et de danse. Je cherche quelqu'un avec qui partager des moments de joie.", denomination: "Traditional", kashrut: "Kosher style", shabbat: "Sometimes" },
    { name: "Leah Benzaquen", age: 24, city: "Marseille", bio: "Étudiante en médecine, j'aime les livres, le cinéma et les longues discussions.", denomination: "Conservative", kashrut: "Kosher at home", shabbat: "Observant" },
    { name: "Miriam Ohayon", age: 26, city: "Nice", bio: "Designer créative, toujours à la recherche d'aventures. La vie est trop courte pour s'ennuyer!", denomination: "Modern Orthodox", kashrut: "Kosher", shabbat: "Observant" },
    { name: "Esther Azoulay", age: 28, city: "Bordeaux", bio: "Avocate le jour, chef cuisinière le soir. Je fais le meilleur couscous de la région.", denomination: "Traditional", kashrut: "Kosher style", shabbat: "Sometimes" },
    { name: "Déborah Sebbag", age: 23, city: "Toulouse", bio: "Jeune entrepreneuse dans la tech. Je code et je cuisine, que demander de plus?", denomination: "Reform", kashrut: "Not strict", shabbat: "Cultural" },
    { name: "Judith Toledano", age: 29, city: "Strasbourg", bio: "Prof de yoga et passionnée de bien-être. Je cherche une belle âme pour partager ma vie.", denomination: "Modern Orthodox", kashrut: "Kosher", shabbat: "Observant" },
    { name: "Rebecca Mimoun", age: 25, city: "Nantes", bio: "Photographe et voyageuse. Mon appareil photo et moi avons vu le monde entier.", denomination: "Conservative", kashrut: "Kosher at home", shabbat: "Sometimes" },
    { name: "Hannah Zerbib", age: 27, city: "Montpellier", bio: "Médecin pédiatre, j'adore les enfants. Family first!", denomination: "Traditional", kashrut: "Kosher style", shabbat: "Observant" },
    { name: "Naomi Abitbol", age: 24, city: "Paris", bio: "Étudiante en droit, passionnée d'art et de culture. Un verre de vin et une bonne conversation, c'est tout ce qu'il me faut.", denomination: "Modern Orthodox", kashrut: "Kosher", shabbat: "Observant" },
  ];

  const maleProfiles = [
    { name: "David Cohen", age: 28, city: "Paris", bio: "Ingénieur en IA, passionné de Torah et de tech. Je cherche ma ezer kenegdo.", denomination: "Modern Orthodox", kashrut: "Kosher", shabbat: "Observant" },
    { name: "Benjamin Levy", age: 30, city: "Lyon", bio: "Entrepreneur dans le retail. J'aime le sport, les voyages et les repas en famille.", denomination: "Traditional", kashrut: "Kosher style", shabbat: "Sometimes" },
    { name: "Jonathan Benzaquen", age: 26, city: "Marseille", bio: "Kiné sportif, je m'occupe des athlètes du coin. Sport le matin, étude le soir.", denomination: "Conservative", kashrut: "Kosher at home", shabbat: "Observant" },
    { name: "Nathan Ohayon", age: 29, city: "Nice", bio: "Chef de projet dans une startup. La côte d'azur, c'est la vie!", denomination: "Modern Orthodox", kashrut: "Kosher", shabbat: "Observant" },
    { name: "Samuel Azoulay", age: 27, city: "Bordeaux", bio: "Sommelier et amateur de bons vins (casher bien sûr). Je cherche quelqu'un pour partager ma passion.", denomination: "Traditional", kashrut: "Kosher", shabbat: "Sometimes" },
    { name: "Michael Sebbag", age: 25, city: "Toulouse", bio: "Développeur full-stack et gamer. Nerd assumé mais sociable!", denomination: "Reform", kashrut: "Not strict", shabbat: "Cultural" },
    { name: "Daniel Toledano", age: 31, city: "Strasbourg", bio: "Dentiste de profession, musicien de passion. Je joue du piano le Shabbat.", denomination: "Modern Orthodox", kashrut: "Kosher", shabbat: "Observant" },
    { name: "Raphaël Mimoun", age: 28, city: "Nantes", bio: "Architecte, je dessine des maisons le jour et des rêves la nuit.", denomination: "Conservative", kashrut: "Kosher at home", shabbat: "Sometimes" },
    { name: "Élie Zerbib", age: 26, city: "Montpellier", bio: "Comptable et passionné de football. OL pour la vie!", denomination: "Traditional", kashrut: "Kosher style", shabbat: "Observant" },
    { name: "Yohan Abitbol", age: 29, city: "Paris", bio: "Avocat d'affaires, fan de cinéma et de bons restaurants. Je cherche une partenaire pour la vie.", denomination: "Modern Orthodox", kashrut: "Kosher", shabbat: "Observant" },
  ];

  // Create users and profiles for women
  for (let i = 0; i < femaleProfiles.length; i++) {
    const p = femaleProfiles[i];
    if (!p) continue;
    const birthYear = new Date().getFullYear() - p.age;
    const birthdate = `${birthYear}-06-15`;
    const firstName = p.name.split(' ')[0] ?? p.name;

    const userResult = await sql`
      INSERT INTO users (email, name, picture, provider, provider_id)
      VALUES (
        ${`fake.female.${i + 1}@mazl.seed`},
        ${p.name},
        ${`https://i.pravatar.cc/400?img=${i + 1}`},
        'seed',
        ${`seed-female-${i + 1}`}
      )
      ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name
      RETURNING id
    `;
    const userId = (userResult[0] as any).id;

    await sql`
      INSERT INTO profiles (user_id, display_name, birthdate, gender, bio, location, denomination, kashrut_level, shabbat_observance, looking_for, is_complete, is_verified, verification_level)
      VALUES (
        ${userId},
        ${firstName},
        ${birthdate},
        'female',
        ${p.bio},
        ${p.city},
        ${p.denomination},
        ${p.kashrut},
        ${p.shabbat},
        'male',
        true,
        true,
        'verified'
      )
      ON CONFLICT (user_id) DO NOTHING
    `;

    // Add profile photo
    await sql`
      INSERT INTO profile_photos (user_id, url, position, is_primary)
      VALUES (${userId}, ${`https://i.pravatar.cc/400?img=${i + 1}`}, 0, true)
      ON CONFLICT DO NOTHING
    `;
  }

  // Create users and profiles for men
  for (let i = 0; i < maleProfiles.length; i++) {
    const p = maleProfiles[i];
    if (!p) continue;
    const birthYear = new Date().getFullYear() - p.age;
    const birthdate = `${birthYear}-06-15`;
    const firstName = p.name.split(' ')[0] ?? p.name;

    const userResult = await sql`
      INSERT INTO users (email, name, picture, provider, provider_id)
      VALUES (
        ${`fake.male.${i + 1}@mazl.seed`},
        ${p.name},
        ${`https://i.pravatar.cc/400?img=${i + 50}`},
        'seed',
        ${`seed-male-${i + 1}`}
      )
      ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name
      RETURNING id
    `;
    const userId = (userResult[0] as any).id;

    await sql`
      INSERT INTO profiles (user_id, display_name, birthdate, gender, bio, location, denomination, kashrut_level, shabbat_observance, looking_for, is_complete, is_verified, verification_level)
      VALUES (
        ${userId},
        ${firstName},
        ${birthdate},
        'male',
        ${p.bio},
        ${p.city},
        ${p.denomination},
        ${p.kashrut},
        ${p.shabbat},
        'female',
        true,
        true,
        'verified'
      )
      ON CONFLICT (user_id) DO NOTHING
    `;

    // Add profile photo
    await sql`
      INSERT INTO profile_photos (user_id, url, position, is_primary)
      VALUES (${userId}, ${`https://i.pravatar.cc/400?img=${i + 50}`}, 0, true)
      ON CONFLICT DO NOTHING
    `;
  }

  console.log("Seeded 20 fake profiles (10 women, 10 men)");
}

// ============ CONVERSATIONS & MESSAGES ============

export async function createConversationForMatch(matchId: number, user1Id: number, user2Id: number) {
  const result = await sql`
    INSERT INTO conversations (match_id, user1_id, user2_id)
    VALUES (${matchId}, ${user1Id}, ${user2Id})
    ON CONFLICT DO NOTHING
    RETURNING *
  `;
  return result[0];
}

export async function getConversations(userId: number) {
  const conversations = await sql`
    SELECT
      c.id,
      c.match_id,
      c.last_message_at,
      c.created_at,
      CASE
        WHEN c.user1_id = ${userId} THEN c.user2_id
        ELSE c.user1_id
      END as other_user_id,
      (
        SELECT CASE
                 WHEN unsent_at IS NOT NULL THEN 'Message retiré'
                 WHEN type = 'photo' THEN 'Photo'
                 WHEN type = 'voice' THEN 'Message vocal'
                 ELSE content
               END
        FROM messages
        WHERE conversation_id = c.id
        ORDER BY id DESC
        LIMIT 1
      ) as last_message,
      (
        SELECT COUNT(*) FROM messages
        WHERE conversation_id = c.id
        AND sender_id != ${userId}
        AND is_read = false
      ) as unread_count
    FROM conversations c
    WHERE (c.user1_id = ${userId} OR c.user2_id = ${userId})
      -- hide conversations with a user blocked in either direction
      AND (CASE WHEN c.user1_id = ${userId} THEN c.user2_id ELSE c.user1_id END) NOT IN (
        SELECT blocked_id FROM blocked_users WHERE blocker_id = ${userId}
        UNION
        SELECT blocker_id FROM blocked_users WHERE blocked_id = ${userId}
      )
    ORDER BY COALESCE(c.last_message_at, c.created_at) DESC
  `;

  if (conversations.length === 0) return [];

  const otherUserIds = conversations.map((c: any) => c.other_user_id);
  const profiles = await sql`
    SELECT
      p.user_id,
      p.display_name,
      ${badgeColumns(sql)},
      u.picture,
      ${primaryPhotoColumns(sql)}
    FROM profiles p
    JOIN users u ON u.id = p.user_id
    WHERE p.user_id IN ${sql(otherUserIds)}
  `;

  const profileMap = new Map<number, any>();
  for (const p of profiles as any[]) {
    profileMap.set(p.user_id, withPublicPicture(p));
  }

  return conversations.map((c: any) => ({
    id: c.id,
    matchId: c.match_id,
    lastMessageAt: c.last_message_at,
    createdAt: c.created_at,
    lastMessage: c.last_message,
    unreadCount: parseInt(c.unread_count),
    otherUser: profileMap.get(c.other_user_id),
  }));
}

export async function getConversationById(conversationId: number) {
  const result = await sql`
    SELECT * FROM conversations WHERE id = ${conversationId}
  `;
  return result.length ? result[0] : null;
}

export async function getConversationByMatchId(matchId: number) {
  const result = await sql`
    SELECT * FROM conversations WHERE match_id = ${matchId}
  `;
  return result.length ? result[0] : null;
}

// ============ EVENTS ============

export interface Event {
  id: number;
  title: string;
  description: string | null;
  event_type: string | null;
  location: string | null;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
  date: string;
  time: string | null;
  end_time: string | null;
  price: number;
  currency: string;
  max_attendees: number | null;
  image_url: string | null;
  organizer_id: number | null;
  is_published: boolean;
  created_at: Date;
  updated_at: Date;
}

export async function createEvent(params: {
  title: string;
  description?: string;
  eventType?: string;
  location?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  date: string;
  time?: string;
  endTime?: string;
  price?: number;
  currency?: string;
  maxAttendees?: number;
  imageUrl?: string;
  organizerId?: number;
  isPublished?: boolean;
}) {
  const result = await sql`
    INSERT INTO events (title, description, event_type, location, address, latitude, longitude, date, time, end_time, price, currency, max_attendees, image_url, organizer_id, is_published)
    VALUES (
      ${params.title},
      ${params.description ?? null},
      ${params.eventType ?? null},
      ${params.location ?? null},
      ${params.address ?? null},
      ${params.latitude ?? null},
      ${params.longitude ?? null},
      ${params.date},
      ${params.time ?? null},
      ${params.endTime ?? null},
      ${params.price ?? 0},
      ${params.currency ?? 'EUR'},
      ${params.maxAttendees ?? null},
      ${params.imageUrl ?? null},
      ${params.organizerId ?? null},
      ${params.isPublished ?? false}
    )
    RETURNING *
  `;
  return result[0] as Event;
}

export async function updateEvent(eventId: number, params: Partial<{
  title: string;
  description: string;
  eventType: string;
  location: string;
  address: string;
  latitude: number;
  longitude: number;
  date: string;
  time: string;
  endTime: string;
  price: number;
  currency: string;
  maxAttendees: number;
  imageUrl: string;
  isPublished: boolean;
}>) {
  const result = await sql`
    UPDATE events SET
      title = COALESCE(${params.title ?? null}, title),
      description = COALESCE(${params.description ?? null}, description),
      event_type = COALESCE(${params.eventType ?? null}, event_type),
      location = COALESCE(${params.location ?? null}, location),
      address = COALESCE(${params.address ?? null}, address),
      latitude = COALESCE(${params.latitude ?? null}, latitude),
      longitude = COALESCE(${params.longitude ?? null}, longitude),
      date = COALESCE(${params.date ?? null}, date),
      time = COALESCE(${params.time ?? null}, time),
      end_time = COALESCE(${params.endTime ?? null}, end_time),
      price = COALESCE(${params.price ?? null}, price),
      currency = COALESCE(${params.currency ?? null}, currency),
      max_attendees = COALESCE(${params.maxAttendees ?? null}, max_attendees),
      image_url = COALESCE(${params.imageUrl ?? null}, image_url),
      is_published = COALESCE(${params.isPublished ?? null}, is_published),
      updated_at = NOW()
    WHERE id = ${eventId}
    RETURNING *
  `;
  return result[0] as Event;
}

export async function deleteEvent(eventId: number) {
  await sql`DELETE FROM events WHERE id = ${eventId}`;
}

export async function getEvents(filters?: {
  type?: string;
  fromDate?: string;
  publishedOnly?: boolean;
  limit?: number;
  offset?: number;
}) {
  const limit = filters?.limit ?? 50;
  const offset = filters?.offset ?? 0;
  const publishedOnly = filters?.publishedOnly ?? true;

  let events;
  if (filters?.type && filters?.fromDate) {
    events = await sql`
      SELECT e.*,
        (SELECT COUNT(*) FROM event_rsvps WHERE event_id = e.id AND status = 'going') as attendee_count
      FROM events e
      WHERE (${!publishedOnly} OR e.is_published = true)
        AND e.event_type = ${filters.type}
        AND e.date >= ${filters.fromDate}
      ORDER BY e.date ASC
      LIMIT ${limit}
      OFFSET ${offset}
    `;
  } else if (filters?.type) {
    events = await sql`
      SELECT e.*,
        (SELECT COUNT(*) FROM event_rsvps WHERE event_id = e.id AND status = 'going') as attendee_count
      FROM events e
      WHERE (${!publishedOnly} OR e.is_published = true)
        AND e.event_type = ${filters.type}
      ORDER BY e.date ASC
      LIMIT ${limit}
      OFFSET ${offset}
    `;
  } else if (filters?.fromDate) {
    events = await sql`
      SELECT e.*,
        (SELECT COUNT(*) FROM event_rsvps WHERE event_id = e.id AND status = 'going') as attendee_count
      FROM events e
      WHERE (${!publishedOnly} OR e.is_published = true)
        AND e.date >= ${filters.fromDate}
      ORDER BY e.date ASC
      LIMIT ${limit}
      OFFSET ${offset}
    `;
  } else {
    events = await sql`
      SELECT e.*,
        (SELECT COUNT(*) FROM event_rsvps WHERE event_id = e.id AND status = 'going') as attendee_count
      FROM events e
      WHERE (${!publishedOnly} OR e.is_published = true)
      ORDER BY e.date ASC
      LIMIT ${limit}
      OFFSET ${offset}
    `;
  }

  return events;
}

export async function getEventById(eventId: number) {
  const result = await sql`
    SELECT e.*,
      (SELECT COUNT(*) FROM event_rsvps WHERE event_id = e.id AND status = 'going') as attendee_count
    FROM events e
    WHERE e.id = ${eventId}
  `;
  return result.length ? result[0] : null;
}

// An event as the public sees it: published only. A draft, like an unknown id,
// is simply absent.
export async function getPublishedEventById(eventId: number) {
  const result = await sql`
    SELECT e.*,
      (SELECT COUNT(*) FROM event_rsvps WHERE event_id = e.id AND status = 'going') as attendee_count
    FROM events e
    WHERE e.id = ${eventId} AND e.is_published = true
  `;
  return result.length ? result[0] : null;
}

export type RsvpOutcome =
  | { readonly kind: "registered"; readonly rsvp: Record<string, unknown> }
  | { readonly kind: "not_found" }
  | { readonly kind: "coming_soon" }
  | { readonly kind: "over" }
  | { readonly kind: "full" };

// Registers a member for a published, open (not "coming soon"), not yet past event. The event row is
// locked for the duration of the transaction, so the seat count and the
// insertion cannot be raced by other registrations of the same event.
export async function rsvpToEvent(eventId: number, userId: number, status: string): Promise<RsvpOutcome> {
  return sql.begin(async (transaction) => {
    const tx = transaction as unknown as typeof sql;
    const events = await tx`
      SELECT max_attendees, date >= CURRENT_DATE AS is_open, availability
      FROM events
      WHERE id = ${eventId} AND is_published = true
      FOR UPDATE
    `;
    const event = events[0] as { max_attendees: number | null; is_open: boolean; availability: string } | undefined;
    if (!event) return { kind: "not_found" } as const;
    if (event.availability === "coming_soon") return { kind: "coming_soon" } as const;
    if (!event.is_open) return { kind: "over" } as const;

    if (status === "going" && event.max_attendees !== null) {
      // The member's own seat does not count against them when they confirm again.
      const taken = await tx`
        SELECT COUNT(*) AS n FROM event_rsvps
        WHERE event_id = ${eventId} AND status = 'going' AND user_id <> ${userId}
      `;
      if (Number((taken[0] as { n: string }).n) >= event.max_attendees) return { kind: "full" } as const;
    }

    const result = await tx`
      INSERT INTO event_rsvps (event_id, user_id, status)
      VALUES (${eventId}, ${userId}, ${status})
      ON CONFLICT (event_id, user_id)
      DO UPDATE SET status = ${status}
      RETURNING *
    `;
    return { kind: "registered", rsvp: result[0] as Record<string, unknown> } as const;
  });
}

export async function deleteRsvp(eventId: number, userId: number) {
  await sql`
    DELETE FROM event_rsvps
    WHERE event_id = ${eventId} AND user_id = ${userId}
  `;
}

export async function getEventAttendees(eventId: number) {
  const attendees = await sql`
    SELECT
      r.id as rsvp_id,
      r.status,
      r.paid,
      r.created_at as rsvp_at,
      u.id as user_id,
      u.email,
      u.name,
      u.picture,
      p.display_name
    FROM event_rsvps r
    JOIN users u ON u.id = r.user_id
    LEFT JOIN profiles p ON p.user_id = u.id
    WHERE r.event_id = ${eventId}
    ORDER BY r.created_at ASC
  `;
  return attendees;
}

export async function getUserRsvp(eventId: number, userId: number) {
  const result = await sql`
    SELECT * FROM event_rsvps
    WHERE event_id = ${eventId} AND user_id = ${userId}
  `;
  return result.length ? result[0] : null;
}

// ============ SUBSCRIPTIONS ============

export interface Subscription {
  id: number;
  user_id: number;
  plan_type: string | null;
  status: string;
  revenuecat_id: string | null; // legacy RevenueCat column, no longer written
  store: string | null;
  product_id: string | null;
  original_transaction_id: string | null;
  started_at: Date | null;
  expires_at: Date | null;
  created_at: Date;
  updated_at: Date;
}

export async function getAllSubscriptions(filters?: {
  status?: string;
  limit?: number;
  offset?: number;
}) {
  const limit = filters?.limit ?? 100;
  const offset = filters?.offset ?? 0;

  if (filters?.status) {
    return await sql`
      SELECT s.*, u.email, u.name, p.display_name
      FROM subscriptions s
      JOIN users u ON u.id = s.user_id
      LEFT JOIN profiles p ON p.user_id = s.user_id
      WHERE s.status = ${filters.status}
      ORDER BY s.created_at DESC
      LIMIT ${limit}
      OFFSET ${offset}
    `;
  }

  return await sql`
    SELECT s.*, u.email, u.name, p.display_name
    FROM subscriptions s
    JOIN users u ON u.id = s.user_id
    LEFT JOIN profiles p ON p.user_id = s.user_id
    ORDER BY s.created_at DESC
    LIMIT ${limit}
    OFFSET ${offset}
  `;
}

// ============ ADMIN STATS ============

export async function getAdminStats() {
  const [users, matches, messages, events, subscriptions] = await Promise.all([
    sql`SELECT
      COUNT(*) as total,
      COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '7 days') as new_this_week,
      COUNT(*) FILTER (WHERE last_login_at > NOW() - INTERVAL '24 hours') as active_today
    FROM users WHERE provider NOT IN ('seed', 'review')`,
    // Test members (provider 'seed') and their matches and messages are not activity.
    sql`SELECT COUNT(*) as total FROM matches m
      WHERE NOT EXISTS (SELECT 1 FROM users s WHERE s.id IN (m.user1_id, m.user2_id) AND s.provider = 'seed')`,
    sql`SELECT COUNT(*) as total FROM messages x
      WHERE NOT EXISTS (
        SELECT 1 FROM conversations c JOIN users s ON s.id IN (c.user1_id, c.user2_id)
        WHERE c.id = x.conversation_id AND s.provider = 'seed')`,
    sql`SELECT
      COUNT(*) as total,
      COUNT(*) FILTER (WHERE is_published = true) as published,
      COUNT(*) FILTER (WHERE date >= CURRENT_DATE) as upcoming
    FROM events`,
    sql`SELECT
      COUNT(*) as total,
      COUNT(*) FILTER (WHERE status = 'active') as active
    FROM subscriptions`,
  ]);

  return {
    users: {
      total: parseInt((users[0] as any).total),
      newThisWeek: parseInt((users[0] as any).new_this_week),
      activeToday: parseInt((users[0] as any).active_today),
    },
    matches: parseInt((matches[0] as any).total),
    messages: parseInt((messages[0] as any).total),
    events: {
      total: parseInt((events[0] as any).total),
      published: parseInt((events[0] as any).published),
      upcoming: parseInt((events[0] as any).upcoming),
    },
    subscriptions: {
      total: parseInt((subscriptions[0] as any).total),
      active: parseInt((subscriptions[0] as any).active),
    },
  };
}

// ============ ADMIN USERS ============

export async function getAdminUsers(filters?: {
  search?: string;
  status?: string;
  hasSubscription?: boolean;
  isVerified?: boolean;
  limit?: number;
  offset?: number;
}) {
  const limit = filters?.limit ?? 50;
  const offset = filters?.offset ?? 0;

  let users;
  if (filters?.search) {
    users = await sql`
      SELECT
        u.id,
        u.email,
        u.name,
        u.picture,
        u.provider,
        u.created_at,
        u.last_login_at,
        u.is_active,
        p.display_name,
        p.location,
        p.is_verified,
        p.verification_level,
        s.plan_type as subscription_plan,
        s.status as subscription_status
      FROM users u
      LEFT JOIN profiles p ON p.user_id = u.id
      LEFT JOIN subscriptions s ON s.user_id = u.id
      WHERE u.provider != 'seed'
        AND (u.email ILIKE ${'%' + filters.search + '%'} OR u.name ILIKE ${'%' + filters.search + '%'} OR p.display_name ILIKE ${'%' + filters.search + '%'})
      ORDER BY u.created_at DESC
      LIMIT ${limit}
      OFFSET ${offset}
    `;
  } else {
    users = await sql`
      SELECT
        u.id,
        u.email,
        u.name,
        u.picture,
        u.provider,
        u.created_at,
        u.last_login_at,
        u.is_active,
        p.display_name,
        p.location,
        p.is_verified,
        p.verification_level,
        s.plan_type as subscription_plan,
        s.status as subscription_status
      FROM users u
      LEFT JOIN profiles p ON p.user_id = u.id
      LEFT JOIN subscriptions s ON s.user_id = u.id
      WHERE u.provider != 'seed'
      ORDER BY u.created_at DESC
      LIMIT ${limit}
      OFFSET ${offset}
    `;
  }

  return users;
}

export async function setUserActiveStatus(userId: number, isActive: boolean) {
  await sql`
    UPDATE users SET is_active = ${isActive}, updated_at = NOW()
    WHERE id = ${userId}
  `;
}

// ============ COUPLE MODE ============

// Advisory-lock class shared with the enforce_single_active_couple trigger
// (the literal 7301 in the trigger body): one lock per member id.
const COUPLE_MEMBER_LOCK_CLASS = 7301;

type SqlExecutor = typeof sql;

export async function createCouple(
  userId: number,
  partnerId: number,
  relationshipStatus: string = 'dating',
  startedAt?: Date,
  executor: SqlExecutor = sql
) {
  // Order user IDs to prevent duplicates
  const [user1, user2] = userId < partnerId ? [userId, partnerId] : [partnerId, userId];

  const result = await executor`
    INSERT INTO couples (user1_id, user2_id, relationship_status, started_at, met_on_mazl_at)
    VALUES (${user1}, ${user2}, ${relationshipStatus}, ${startedAt || new Date()}, ${new Date()})
    ON CONFLICT (user1_id, user2_id) DO UPDATE SET
      status = 'active',
      relationship_status = ${relationshipStatus},
      updated_at = NOW()
    RETURNING *
  `;

  return result[0];
}

export async function getCouple(userId: number) {
  const result = await sql`
    SELECT
      c.*,
      CASE WHEN c.user1_id = ${userId} THEN c.user2_id ELSE c.user1_id END as partner_id,
      CASE WHEN c.user1_id = ${userId} THEN p2.display_name ELSE p1.display_name END as partner_name,
      CASE WHEN c.user1_id = ${userId} THEN u2.picture ELSE u1.picture END as partner_picture
    FROM couples c
    LEFT JOIN profiles p1 ON p1.user_id = c.user1_id
    LEFT JOIN profiles p2 ON p2.user_id = c.user2_id
    LEFT JOIN users u1 ON u1.id = c.user1_id
    LEFT JOIN users u2 ON u2.id = c.user2_id
    WHERE (c.user1_id = ${userId} OR c.user2_id = ${userId})
      AND c.status = 'active'
    ORDER BY c.id DESC
    LIMIT 1
  `;

  const couple = result[0];
  if (!couple) return null;
  const pictures = await publicPicturesFor(sql, [couple.partner_id]);
  couple.partner_picture = pictures.get(couple.partner_id) ?? null;
  return couple;
}

// Alias for getCouple - returns the couple with ID for the user
export async function getCoupleByUserId(userId: number) {
  return await getCouple(userId);
}

export async function updateCoupleStatus(coupleId: number, status: string) {
  await sql`
    UPDATE couples SET status = ${status}, updated_at = NOW()
    WHERE id = ${coupleId}
  `;
}

export async function updateRelationshipStatus(coupleId: number, relationshipStatus: string) {
  await sql`
    UPDATE couples SET relationship_status = ${relationshipStatus}, updated_at = NOW()
    WHERE id = ${coupleId}
  `;
}

export async function deleteCouple(coupleId: number) {
  await sql`
    UPDATE couples SET status = 'ended', updated_at = NOW()
    WHERE id = ${coupleId}
  `;
}

// ============ COUPLE REQUESTS (demande / acceptation de couple) ============

export type CoupleRequestStatus = 'pending' | 'accepted' | 'rejected' | 'cancelled';

export interface CoupleRequestRow {
  id: number;
  requester_id: number;
  target_id: number;
  status: CoupleRequestStatus;
  created_at: Date;
  updated_at: Date;
}

// Limits on asking the same person again: nobody can be pestered into a couple.
export const COUPLE_REQUEST_COOLDOWN_DAYS = 7;
export const COUPLE_REQUEST_MAX_REFUSED_PER_PAIR = 3;
export const COUPLE_REQUEST_MAX_PER_DAY_TO_SAME_PERSON = 3;

export type CreateCoupleRequestResult =
  | { ok: true; request: CoupleRequestRow }
  | { ok: false; error: string; status?: 400 | 409 | 429 };

export type CoupleStatusWith =
  | 'none'
  | 'pending_sent'
  | 'pending_received'
  | 'coupled';

export interface CoupleRequestView {
  id: number;
  requester_id: number;
  target_id: number;
  status: CoupleRequestStatus;
  created_at: Date;
  requester_name: string | null;
  requester_picture: string | null;
  target_name: string | null;
  target_picture: string | null;
}

/**
 * Create a pending couple request. Refuses self-targeting, blocked pairs,
 * an existing pending request in either direction, or an already-active couple.
 */
export async function createCoupleRequest(
  requesterId: number,
  targetId: number
): Promise<CreateCoupleRequestResult> {
  if (requesterId === targetId) {
    return { ok: false, error: 'Cannot send a couple request to yourself' };
  }

  if (await isBlockedBetween(requesterId, targetId)) {
    return { ok: false, error: 'User is unavailable' };
  }

  // Refuse if either user is already in an active couple.
  const existingCouple = await sql`
    SELECT 1 FROM couples
    WHERE status = 'active'
      AND (user1_id IN (${requesterId}, ${targetId})
           OR user2_id IN (${requesterId}, ${targetId}))
    LIMIT 1
  `;
  if (existingCouple.length > 0) {
    return { ok: false, error: 'One of the users is already in a couple' };
  }

  // Refuse if a pending request already exists in either direction.
  const existingPending = await sql`
    SELECT 1 FROM couple_requests
    WHERE status = 'pending'
      AND ((requester_id = ${requesterId} AND target_id = ${targetId})
        OR (requester_id = ${targetId} AND target_id = ${requesterId}))
    LIMIT 1
  `;
  if (existingPending.length > 0) {
    return { ok: false, error: 'A pending couple request already exists' };
  }

  // Each refusal counts against the pair, in either direction, for good.
  const [refused] = await sql<{ total: string }[]>`
    SELECT COUNT(*)::text AS total FROM couple_requests
    WHERE status = 'rejected'
      AND ((requester_id = ${requesterId} AND target_id = ${targetId})
        OR (requester_id = ${targetId} AND target_id = ${requesterId}))
  `;
  if (Number(refused?.total ?? 0) >= COUPLE_REQUEST_MAX_REFUSED_PER_PAIR) {
    return {
      ok: false,
      status: 409,
      error: 'Too many declined couple requests with this person: no new request is possible',
    };
  }

  // A refusal is respected for a while before the same person may ask again.
  const recentlyRefused = await sql`
    SELECT 1 FROM couple_requests
    WHERE status = 'rejected'
      AND requester_id = ${requesterId} AND target_id = ${targetId}
      AND updated_at > NOW() - ${COUPLE_REQUEST_COOLDOWN_DAYS} * INTERVAL '1 day'
    LIMIT 1
  `;
  if (recentlyRefused.length > 0) {
    return {
      ok: false,
      status: 429,
      error: `This person declined your request: wait ${COUPLE_REQUEST_COOLDOWN_DAYS} days before asking again`,
    };
  }

  // Sending then cancelling in a loop would notify the target each time.
  const [recent] = await sql<{ total: string }[]>`
    SELECT COUNT(*)::text AS total FROM couple_requests
    WHERE requester_id = ${requesterId} AND target_id = ${targetId}
      AND created_at > NOW() - INTERVAL '1 day'
  `;
  if (Number(recent?.total ?? 0) >= COUPLE_REQUEST_MAX_PER_DAY_TO_SAME_PERSON) {
    return {
      ok: false,
      status: 429,
      error: 'Too many couple requests to this person today: try again tomorrow',
    };
  }

  const rows = await sql`
    INSERT INTO couple_requests (requester_id, target_id, status)
    VALUES (${requesterId}, ${targetId}, 'pending')
    RETURNING *
  `;
  return { ok: true, request: rows[0] as CoupleRequestRow };
}

export async function getCoupleRequestById(
  id: number
): Promise<CoupleRequestRow | null> {
  const rows = await sql`
    SELECT * FROM couple_requests WHERE id = ${id} LIMIT 1
  `;
  return rows.length ? (rows[0] as CoupleRequestRow) : null;
}

export type RespondToCoupleRequestResult =
  | { ok: true; action: 'accepted'; couple: Record<string, unknown> }
  | { ok: true; action: 'rejected' }
  | { ok: false; status: number; error: string };

function isUniqueViolation(error: unknown): boolean {
  return typeof error === 'object' && error !== null && (error as { code?: unknown }).code === '23505';
}

/**
 * Accept or reject a couple request. Only the target may respond (IDOR guard).
 * Everything an acceptance depends on is re-checked inside one transaction that
 * holds a lock on both members, so two simultaneous acceptances cannot both
 * pass: the second one sees the couple the first one created.
 */
export async function respondToCoupleRequest(
  requestId: number,
  userId: number,
  action: 'accept' | 'reject'
): Promise<RespondToCoupleRequestResult> {
  const request = await getCoupleRequestById(requestId);
  if (!request) {
    return { ok: false, status: 404, error: 'Couple request not found' };
  }
  if (request.target_id !== userId) {
    return { ok: false, status: 403, error: 'Forbidden' };
  }

  try {
    return await sql.begin(async (transaction) => {
      const tx = transaction as unknown as SqlExecutor;
      const [low, high] = request.requester_id < request.target_id
        ? [request.requester_id, request.target_id]
        : [request.target_id, request.requester_id];
      await tx`SELECT pg_advisory_xact_lock(${COUPLE_MEMBER_LOCK_CLASS}, ${low})`;
      await tx`SELECT pg_advisory_xact_lock(${COUPLE_MEMBER_LOCK_CLASS}, ${high})`;

      const [current] = await tx<{ status: CoupleRequestStatus }[]>`
        SELECT status FROM couple_requests WHERE id = ${requestId} FOR UPDATE
      `;
      if (!current || current.status !== 'pending') {
        return { ok: false, status: 409, error: 'Couple request is no longer pending' } as const;
      }

      if (action === 'reject') {
        await tx`
          UPDATE couple_requests
          SET status = 'rejected', updated_at = NOW()
          WHERE id = ${requestId}
        `;
        return { ok: true, action: 'rejected' } as const;
      }

      // Blocking or unmatching after the request was sent must stop the couple.
      const blocked = await tx`
        SELECT 1 FROM blocked_users
        WHERE (blocker_id = ${low} AND blocked_id = ${high})
           OR (blocker_id = ${high} AND blocked_id = ${low})
        LIMIT 1
      `;
      if (blocked.length > 0) {
        return { ok: false, status: 403, error: 'User is unavailable' } as const;
      }
      const matched = await tx`
        SELECT 1 FROM matches WHERE user1_id = ${low} AND user2_id = ${high} LIMIT 1
      `;
      if (matched.length === 0) {
        return { ok: false, status: 403, error: 'not_matched' } as const;
      }

      const alreadyCoupled = await tx`
        SELECT 1 FROM couples
        WHERE status = 'active'
          AND (user1_id IN (${low}, ${high}) OR user2_id IN (${low}, ${high}))
        LIMIT 1
      `;
      if (alreadyCoupled.length > 0) {
        return { ok: false, status: 409, error: 'One of the users is already in a couple' } as const;
      }

      const couple = await createCouple(request.requester_id, request.target_id, 'dating', undefined, tx);
      await tx`
        UPDATE couple_requests
        SET status = 'accepted', updated_at = NOW()
        WHERE id = ${requestId}
      `;
      // The two people are taken: whatever else was waiting for either of them is void.
      await tx`
        UPDATE couple_requests
        SET status = 'cancelled', updated_at = NOW()
        WHERE status = 'pending' AND id <> ${requestId}
          AND (requester_id IN (${low}, ${high}) OR target_id IN (${low}, ${high}))
      `;
      return { ok: true, action: 'accepted', couple: couple as Record<string, unknown> } as const;
    });
  } catch (error: unknown) {
    // The database guard (one active couple per member) caught a race the
    // checks above could not see.
    if (isUniqueViolation(error)) {
      return { ok: false, status: 409, error: 'One of the users is already in a couple' };
    }
    throw error;
  }
}

export type CancelCoupleRequestResult =
  | { ok: true }
  | { ok: false; status: number; error: string };

/**
 * Cancel a pending couple request. Only the requester may cancel (IDOR guard).
 */
export async function cancelCoupleRequest(
  requestId: number,
  userId: number
): Promise<CancelCoupleRequestResult> {
  const request = await getCoupleRequestById(requestId);
  if (!request) {
    return { ok: false, status: 404, error: 'Couple request not found' };
  }
  if (request.requester_id !== userId) {
    return { ok: false, status: 403, error: 'Forbidden' };
  }
  if (request.status !== 'pending') {
    return { ok: false, status: 409, error: 'Couple request is no longer pending' };
  }

  await sql`
    UPDATE couple_requests
    SET status = 'cancelled', updated_at = NOW()
    WHERE id = ${requestId}
  `;
  return { ok: true };
}

/** Pending requests sent by AND received by the user, with names/photos on both sides. */
export async function getCoupleRequestsForUser(
  userId: number
): Promise<{ sent: CoupleRequestView[]; received: CoupleRequestView[] }> {
  const rows = await sql`
    SELECT
      cr.id,
      cr.requester_id,
      cr.target_id,
      cr.status,
      cr.created_at,
      rp.display_name AS requester_name,
      ru.picture AS requester_picture,
      tp.display_name AS target_name,
      tu.picture AS target_picture
    FROM couple_requests cr
    LEFT JOIN profiles rp ON rp.user_id = cr.requester_id
    LEFT JOIN users ru ON ru.id = cr.requester_id
    LEFT JOIN profiles tp ON tp.user_id = cr.target_id
    LEFT JOIN users tu ON tu.id = cr.target_id
    WHERE cr.status = 'pending'
      AND (cr.requester_id = ${userId} OR cr.target_id = ${userId})
      AND NOT EXISTS (
        SELECT 1 FROM blocked_users b
        WHERE (b.blocker_id = cr.requester_id AND b.blocked_id = cr.target_id)
           OR (b.blocker_id = cr.target_id AND b.blocked_id = cr.requester_id)
      )
    ORDER BY cr.created_at DESC
  `;

  const memberIds = new Set<number>();
  for (const raw of rows as unknown as CoupleRequestView[]) {
    memberIds.add(raw.requester_id);
    memberIds.add(raw.target_id);
  }
  const pictures = await publicPicturesFor(sql, [...memberIds]);

  const sent: CoupleRequestView[] = [];
  const received: CoupleRequestView[] = [];
  for (const raw of rows as unknown as CoupleRequestView[]) {
    const row: CoupleRequestView = {
      ...raw,
      requester_picture: pictures.get(raw.requester_id) ?? null,
      target_picture: pictures.get(raw.target_id) ?? null,
    };
    if (row.requester_id === userId) {
      sent.push(row);
    } else {
      received.push(row);
    }
  }
  return { sent, received };
}

/** Relationship state between two users: none / pending_sent / pending_received / coupled. */
export async function getCoupleStatusWith(
  userId: number,
  otherUserId: number
): Promise<CoupleStatusWith> {
  const coupled = await sql`
    SELECT 1 FROM couples
    WHERE status = 'active'
      AND ((user1_id = ${userId} AND user2_id = ${otherUserId})
        OR (user1_id = ${otherUserId} AND user2_id = ${userId}))
    LIMIT 1
  `;
  if (coupled.length > 0) return 'coupled';

  const pending = await sql`
    SELECT requester_id, target_id FROM couple_requests
    WHERE status = 'pending'
      AND ((requester_id = ${userId} AND target_id = ${otherUserId})
        OR (requester_id = ${otherUserId} AND target_id = ${userId}))
      AND NOT EXISTS (
        SELECT 1 FROM blocked_users b
        WHERE (b.blocker_id = ${userId} AND b.blocked_id = ${otherUserId})
           OR (b.blocker_id = ${otherUserId} AND b.blocked_id = ${userId})
      )
    LIMIT 1
  `;
  if (pending.length > 0) {
    const row = pending[0] as { requester_id: number; target_id: number };
    return row.requester_id === userId ? 'pending_sent' : 'pending_received';
  }

  return 'none';
}

/**
 * Archive (per-user) all of the user's conversations except the one(s) with the
 * given partner. Purely additive: getConversations is untouched, callers opt in.
 * Optionally posts a farewell message into each archived conversation, except
 * the ones with a person who is in a block relationship with the user, either
 * way: a block must never be a way to keep writing to someone.
 */
export async function archiveConversationsExceptPartner(
  userId: number,
  partnerUserId: number | null,
  message?: string
): Promise<{ archived: number }> {
  const conversations = await sql`
    SELECT
      c.id,
      CASE WHEN c.user1_id = ${userId} THEN c.user2_id ELSE c.user1_id END AS other_user_id
    FROM conversations c
    WHERE (c.user1_id = ${userId} OR c.user2_id = ${userId})
  `;

  const blockedIds = await getBlockedUserIds(userId);
  let archived = 0;
  for (const conv of conversations as unknown as Array<{ id: number; other_user_id: number }>) {
    if (partnerUserId !== null && conv.other_user_id === partnerUserId) continue;

    await sql`
      INSERT INTO archived_conversations (user_id, conversation_id)
      VALUES (${userId}, ${conv.id})
      ON CONFLICT (user_id, conversation_id) DO NOTHING
    `;
    archived += 1;

    if (message && message.trim().length > 0 && !blockedIds.has(conv.other_user_id)) {
      await sql`
        INSERT INTO messages (conversation_id, sender_id, content)
        VALUES (${conv.id}, ${userId}, ${message})
      `;
    }
  }

  return { archived };
}

// Daily questions for couples
const DAILY_QUESTIONS = [
  { question: "Quel est ton moment prefere de la semaine ensemble ?", category: "Connection" },
  { question: "Si on pouvait voyager n'importe ou, ou irais-tu ?", category: "Reves" },
  { question: "Qu'est-ce qui t'a fait sourire aujourd'hui ?", category: "Quotidien" },
  { question: "Comment aimerais-tu celebrer notre prochain Shabbat ?", category: "Judaisme" },
  { question: "Quel trait de caractere admires-tu le plus chez moi ?", category: "Appreciation" },
  { question: "Qu'est-ce qui te manque le plus quand on n'est pas ensemble ?", category: "Connection" },
  { question: "Si tu pouvais apprendre une nouvelle competence, ce serait quoi ?", category: "Reves" },
  { question: "Quel est ton souvenir prefere de notre relation ?", category: "Souvenirs" },
  { question: "Comment te sens-tu aujourd'hui sur une echelle de 1 a 10 ?", category: "Bien-etre" },
  { question: "Quelle est la chose la plus importante dans un couple selon toi ?", category: "Valeurs" },
];

export async function getDailyQuestion(coupleId: number) {
  // Check if there's already a question for today
  const existing = await sql`
    SELECT * FROM couple_questions
    WHERE couple_id = ${coupleId}
      AND asked_at = CURRENT_DATE
  `;

  if (existing.length > 0) {
    return existing[0];
  }

  // Pick a random question
  const randomIndex = Math.floor(Math.random() * DAILY_QUESTIONS.length);
  const questionData = DAILY_QUESTIONS[randomIndex];
  if (!questionData) throw new Error("No daily question available");

  // Create new question for today
  const result = await sql`
    INSERT INTO couple_questions (couple_id, question, category, asked_at)
    VALUES (${coupleId}, ${questionData.question}, ${questionData.category}, CURRENT_DATE)
    RETURNING *
  `;

  return result[0];
}

// Records one member's answer. The question must belong to the couple named in
// the call, otherwise another couple's answer could be overwritten by id.
// Returns false when nothing was written (unknown couple, outsider, or a
// question that is not this couple's).
export async function answerDailyQuestion(
  coupleId: number,
  questionId: number,
  userId: number,
  answer: string
): Promise<boolean> {
  const couple = await sql<{ user1_id: number; user2_id: number }[]>`
    SELECT user1_id, user2_id FROM couples WHERE id = ${coupleId}
  `;
  const members = couple[0];
  if (!members) return false;

  if (members.user1_id === userId) {
    const updated = await sql`
      UPDATE couple_questions
      SET user1_answer = ${answer}
      WHERE id = ${questionId} AND couple_id = ${coupleId}
      RETURNING id
    `;
    return updated.length > 0;
  }
  if (members.user2_id === userId) {
    const updated = await sql`
      UPDATE couple_questions
      SET user2_answer = ${answer}
      WHERE id = ${questionId} AND couple_id = ${coupleId}
      RETURNING id
    `;
    return updated.length > 0;
  }
  return false;
}

export async function getCoupleQuestionHistory(coupleId: number, limit = 30) {
  const questions = await sql`
    SELECT * FROM couple_questions
    WHERE couple_id = ${coupleId}
    ORDER BY asked_at DESC
    LIMIT ${limit}
  `;
  return questions;
}

// Milestones
export async function recordMilestone(coupleId: number, milestoneType: string) {
  // Check if milestone already exists
  const existing = await sql`
    SELECT id FROM couple_milestones
    WHERE couple_id = ${coupleId} AND milestone_type = ${milestoneType}
  `;

  if (existing.length > 0) return existing[0];

  const result = await sql`
    INSERT INTO couple_milestones (couple_id, milestone_type)
    VALUES (${coupleId}, ${milestoneType})
    RETURNING *
  `;

  return result[0];
}

export async function getCoupleMilestones(coupleId: number) {
  const milestones = await sql`
    SELECT * FROM couple_milestones
    WHERE couple_id = ${coupleId}
    ORDER BY achieved_at DESC
  `;
  return milestones;
}

// Check and record automatic milestones
export async function checkAndRecordMilestones(coupleId: number, daysTogether: number) {
  const milestonesToCheck = [
    { days: 7, type: 'first_week' },
    { days: 30, type: 'first_month' },
    { days: 90, type: 'three_months' },
    { days: 180, type: 'six_months' },
    { days: 365, type: 'first_year' },
  ];

  for (const m of milestonesToCheck) {
    if (daysTogether >= m.days) {
      await recordMilestone(coupleId, m.type);
    }
  }
}

// ============ ADMIN UTILITIES ============

// Reset all swipes for a user (admin only)
export async function resetUserSwipes(userId: number) {
  const result = await sql`
    DELETE FROM swipes WHERE user_id = ${userId}
    RETURNING id
  `;
  return { deleted: result.length };
}

// Reset swipes for all users (admin only)
export async function resetAllSwipes() {
  const result = await sql`
    DELETE FROM swipes
    RETURNING id
  `;
  return { deleted: result.length };
}

// ============ MODULE 1: GESTION MEMBRES COMPLÈTE ============

// Get user detail for admin
export async function getAdminUserDetail(userId: number) {
  const result = await sql`
    SELECT
      u.id,
      u.email,
      u.name,
      u.picture,
      u.provider,
      u.created_at,
      u.last_login_at,
      u.is_active,
      p.display_name,
      p.birthdate,
      p.gender,
      p.bio,
      p.location,
      p.denomination,
      p.kashrut_level,
      p.shabbat_observance,
      p.looking_for,
      p.is_verified,
      p.verification_level,
      s.plan_type as subscription_plan,
      s.status as subscription_status,
      s.expires_at as subscription_expires,
      (SELECT COUNT(*) FROM swipes WHERE user_id = u.id) as total_swipes,
      (SELECT COUNT(*) FROM matches WHERE user1_id = u.id OR user2_id = u.id) as total_matches,
      (SELECT COUNT(*) FROM messages WHERE sender_id = u.id) as total_messages,
      (SELECT COUNT(*) FROM event_rsvps WHERE user_id = u.id) as total_events
    FROM users u
    LEFT JOIN profiles p ON p.user_id = u.id
    LEFT JOIN subscriptions s ON s.user_id = u.id
    WHERE u.id = ${userId}
  `;

  if (result.length === 0) return null;

  const user = result[0] as any;

  // Get profile photos
  const photos = await sql`
    SELECT id, url, position FROM profile_photos
    WHERE user_id = ${userId}
    ORDER BY position ASC
  `;

  // Get active bans
  const bans = await sql`
    SELECT * FROM user_bans
    WHERE user_id = ${userId}
    ORDER BY banned_at DESC
  `;

  // Get admin notes
  const notes = await sql`
    SELECT * FROM admin_notes
    WHERE user_id = ${userId}
    ORDER BY created_at DESC
    LIMIT 20
  `;

  return {
    ...user,
    photos: publicPhotoUrls(photos as any[]),
    bans,
    notes,
  };
}

// Ban user
export async function banUser(params: {
  userId: number;
  reason: string;
  bannedBy: string;
  expiresAt?: Date;
  isPermanent?: boolean;
}) {
  // Deactivate user
  await sql`UPDATE users SET is_active = false WHERE id = ${params.userId}`;

  // Create ban record
  const result = await sql`
    INSERT INTO user_bans (user_id, reason, banned_by, expires_at, is_permanent)
    VALUES (${params.userId}, ${params.reason}, ${params.bannedBy}, ${params.expiresAt ?? null}, ${params.isPermanent ?? false})
    RETURNING *
  `;

  // A permanent ban follows the identity document: it cannot open a new account.
  if (params.isPermanent) {
    await sql`
      INSERT INTO banned_document_fingerprints (doc_fingerprint)
      SELECT doc_fingerprint FROM identity_verifications WHERE user_id = ${params.userId}
      ON CONFLICT DO NOTHING
    `;
  }

  // Log action
  await logModerationAction({
    adminEmail: params.bannedBy,
    action: 'ban_user',
    targetType: 'user',
    targetId: params.userId,
    details: { reason: params.reason, isPermanent: params.isPermanent },
  });

  return result[0];
}

// Unban user
export async function unbanUser(userId: number, unbannedBy: string) {
  // Reactivate user
  await sql`UPDATE users SET is_active = true WHERE id = ${userId}`;

  // Update ban record
  await sql`
    UPDATE user_bans
    SET unbanned_at = NOW(), unbanned_by = ${unbannedBy}
    WHERE user_id = ${userId} AND unbanned_at IS NULL
  `;
  await sql`
    DELETE FROM banned_document_fingerprints
    WHERE doc_fingerprint IN (SELECT doc_fingerprint FROM identity_verifications WHERE user_id = ${userId})
  `;

  // Log action
  await logModerationAction({
    adminEmail: unbannedBy,
    action: 'unban_user',
    targetType: 'user',
    targetId: userId,
  });
}

// Add admin note
export async function addAdminNote(params: {
  userId: number;
  adminEmail: string;
  note: string;
}) {
  const result = await sql`
    INSERT INTO admin_notes (user_id, admin_email, note)
    VALUES (${params.userId}, ${params.adminEmail}, ${params.note})
    RETURNING *
  `;
  return result[0];
}

// Get user activity history
export async function getUserActivity(userId: number, limit = 50) {
  // Get recent swipes
  const swipes = await sql`
    SELECT 'swipe' as type, s.action, s.created_at, p.display_name as target_name
    FROM swipes s
    LEFT JOIN profiles p ON p.user_id = s.target_user_id
    WHERE s.user_id = ${userId}
    ORDER BY s.created_at DESC
    LIMIT ${limit}
  `;

  // Get recent matches
  const matches = await sql`
    SELECT 'match' as type, m.created_at,
      CASE WHEN m.user1_id = ${userId} THEN p2.display_name ELSE p1.display_name END as partner_name
    FROM matches m
    LEFT JOIN profiles p1 ON p1.user_id = m.user1_id
    LEFT JOIN profiles p2 ON p2.user_id = m.user2_id
    WHERE m.user1_id = ${userId} OR m.user2_id = ${userId}
    ORDER BY m.created_at DESC
    LIMIT ${limit}
  `;

  // Get recent messages (count per conversation)
  const messages = await sql`
    SELECT 'message' as type, c.id as conversation_id, COUNT(m.id) as count, MAX(m.created_at) as created_at
    FROM messages m
    JOIN conversations c ON c.id = m.conversation_id
    WHERE m.sender_id = ${userId}
    GROUP BY c.id
    ORDER BY MAX(m.created_at) DESC
    LIMIT ${limit}
  `;

  // Get event RSVPs
  const rsvps = await sql`
    SELECT 'event_rsvp' as type, r.created_at, e.title as event_title, r.status
    FROM event_rsvps r
    JOIN events e ON e.id = r.event_id
    WHERE r.user_id = ${userId}
    ORDER BY r.created_at DESC
    LIMIT ${limit}
  `;

  return { swipes, matches, messages, rsvps };
}

// The waitlist is tied to a member by e-mail address only (case aside). Its rows
// go with the account. An entry whose identity documents still have a file to
// purge is kept, with its address and token wiped, so that the documents purge
// (src/features/documents) still finds those files: deleting the row would
// cascade-delete the document rows and leave the files on disk for good.
async function eraseWaitlistEntries(tx: typeof sql, userId: number): Promise<void> {
  const entries = await tx`
    SELECT w.id,
      EXISTS (
        SELECT 1 FROM documents d
        WHERE d.waitlist_id = w.id AND d.filename IS NOT NULL AND d.purged_at IS NULL
      ) AS has_files
    FROM waitlist w
    WHERE LOWER(w.email) = (SELECT LOWER(email) FROM users WHERE id = ${userId})
  `;
  for (const entry of entries as unknown as Array<{ id: number; has_files: boolean }>) {
    if (entry.has_files) {
      await tx`
        UPDATE waitlist
        SET email = ${`erased-${entry.id}@erased.invalid`}, verification_token = NULL
        WHERE id = ${entry.id}
      `;
    } else {
      await tx`DELETE FROM waitlist WHERE id = ${entry.id}`;
    }
  }
}

// Every row of a member, inside the caller's transaction (the chat files on disk
// are the caller's concern). Used by the account erasure and by the purge of
// sample data.
export async function eraseUserRows(tx: typeof sql, userId: number): Promise<void> {
  // The user's conversations first (their messages, reactions and media rows
  // cascade): conversations.user*_id and messages.sender_id have no cascade,
  // so a conversation that no match owns would otherwise block the deletion.
  await tx`DELETE FROM conversations WHERE user1_id = ${userId} OR user2_id = ${userId}`;
  // Events they organised stay (others registered for them), without an organiser.
  await tx`UPDATE events SET organizer_id = NULL WHERE organizer_id = ${userId}`;
  // Couple memories they wrote reference users without ON DELETE.
  await tx`DELETE FROM couple_memories WHERE created_by = ${userId}`;
  // Then the rest, in order (respecting foreign keys)
  await tx`DELETE FROM admin_notes WHERE user_id = ${userId}`;
  await tx`DELETE FROM user_bans WHERE user_id = ${userId}`;
  await tx`DELETE FROM profile_photos WHERE user_id = ${userId}`;
  await tx`DELETE FROM swipes WHERE user_id = ${userId} OR target_user_id = ${userId}`;
  await tx`DELETE FROM event_rsvps WHERE user_id = ${userId}`;
  await tx`DELETE FROM subscriptions WHERE user_id = ${userId}`;
  await eraseCredits(tx, userId);
  await tx`DELETE FROM profiles WHERE user_id = ${userId}`;
  await eraseWaitlistEntries(tx, userId);
  await tx`DELETE FROM users WHERE id = ${userId}`;
}

// Delete user completely
export async function deleteUserCompletely(userId: number, adminEmail: string) {
  // Log before deletion
  await logModerationAction({
    adminEmail,
    action: 'delete_user',
    targetType: 'user',
    targetId: userId,
  });

  // One transaction: the chat files are removed from disk only once it has
  // committed (see the erasure guard around this call in the admin routes).
  await sql.begin(async (transaction) => {
    await eraseUserRows(transaction as unknown as typeof sql, userId);
  });

  return { deleted: true };
}

// Update user verification level
export async function setUserVerificationLevel(userId: number, level: string) {
  await sql`
    UPDATE profiles
    SET verification_level = ${level}, is_verified = ${level !== 'none'}
    WHERE user_id = ${userId}
  `;
}

// ============ PROFILE PHOTOS ============

// Get profile photos
export async function getProfilePhotos(userId: number) {
  const photos = await sql`
    SELECT id, url, position, is_primary, created_at
    FROM profile_photos
    WHERE user_id = ${userId}
    ORDER BY position ASC
  `;
  return photos;
}

export const MAX_PROFILE_PHOTOS = 6;
// First key of the advisory lock that serialises a member's photo additions.
const PROFILE_PHOTOS_LOCK_NAMESPACE = 7202;

export class ProfilePhotoLimitError extends Error {
  constructor() {
    super(`Maximum of ${MAX_PROFILE_PHOTOS} photos reached`);
    this.name = "ProfilePhotoLimitError";
  }
}

// The photo does not exist or belongs to someone else: both look the same.
export class ProfilePhotoNotFoundError extends Error {
  constructor() {
    super("Photo not found");
    this.name = "ProfilePhotoNotFoundError";
  }
}

// A reorder that names photos that are not the member's.
export class ProfilePhotoSelectionError extends Error {
  constructor() {
    super("Invalid photo ID");
    this.name = "ProfilePhotoSelectionError";
  }
}

// Add profile photo
export async function addProfilePhoto(params: {
  userId: number;
  url: string;
  position?: number;
  isPrimary?: boolean;
}) {
  // The count, the cap and the insert run under a lock held per member until
  // the transaction ends: simultaneous uploads cannot overrun the cap.
  return sql.begin(async (transaction) => {
    const tx = transaction as unknown as typeof sql;
    await tx`SELECT pg_advisory_xact_lock(${PROFILE_PHOTOS_LOCK_NAMESPACE}, ${params.userId})`;
    const existingPhotos = await tx`SELECT id FROM profile_photos WHERE user_id = ${params.userId}`;
    if (existingPhotos.length >= MAX_PROFILE_PHOTOS) throw new ProfilePhotoLimitError();

    // If this is the first photo or marked as primary, set it as primary
    const shouldBePrimary = params.isPrimary || existingPhotos.length === 0;
    const position = params.position ?? existingPhotos.length;

    // If setting as primary, unset other primaries
    if (shouldBePrimary) {
      await tx`
        UPDATE profile_photos SET is_primary = false WHERE user_id = ${params.userId}
      `;
    }

    const result = await tx`
      INSERT INTO profile_photos (user_id, url, position, is_primary)
      VALUES (${params.userId}, ${params.url}, ${position}, ${shouldBePrimary})
      RETURNING *
    `;
    return result[0];
  });
}

// Delete profile photo
export async function deleteProfilePhoto(photoId: number, userId: number) {
  // Get the photo to check if it's primary
  const photo = await sql`
    SELECT * FROM profile_photos WHERE id = ${photoId} AND user_id = ${userId}
  `;

  const deletedPhoto = photo[0];
  if (!deletedPhoto) {
    throw new ProfilePhotoNotFoundError();
  }

  await sql`DELETE FROM profile_photos WHERE id = ${photoId} AND user_id = ${userId}`;

  // If deleted photo was primary, set the first remaining as primary
  if (deletedPhoto.is_primary) {
    await sql`
      UPDATE profile_photos
      SET is_primary = true
      WHERE user_id = ${userId}
      AND id = (SELECT id FROM profile_photos WHERE user_id = ${userId} ORDER BY position ASC LIMIT 1)
    `;
  }

  // Reorder remaining photos
  const remaining = await sql`
    SELECT id FROM profile_photos WHERE user_id = ${userId} ORDER BY position ASC
  `;

  for (let i = 0; i < remaining.length; i++) {
    const row = remaining[i];
    if (!row) continue;
    await sql`UPDATE profile_photos SET position = ${i} WHERE id = ${row.id}`;
  }
}

// Reorder profile photos
export async function reorderProfilePhotos(userId: number, photoIds: number[]) {
  // Verify all photos belong to user
  const userPhotos = await sql`
    SELECT id FROM profile_photos WHERE user_id = ${userId}
  `;

  const userPhotoIds = new Set(userPhotos.map((p: any) => p.id));
  for (const id of photoIds) {
    if (!userPhotoIds.has(id)) {
      throw new ProfilePhotoSelectionError();
    }
  }

  // Update positions
  for (let i = 0; i < photoIds.length; i++) {
    const photoId = photoIds[i];
    if (photoId === undefined) continue;
    await sql`
      UPDATE profile_photos
      SET position = ${i}, is_primary = ${i === 0}
      WHERE id = ${photoId} AND user_id = ${userId}
    `;
  }

  return await getProfilePhotos(userId);
}

// Set profile photo as primary
export async function setProfilePhotoPrimary(photoId: number, userId: number) {
  // One statement sequence in one transaction, and only for the member's own
  // photo: otherwise the current primary would be unset for nothing.
  await sql.begin(async (transaction) => {
    const tx = transaction as unknown as typeof sql;
    const own = await tx`SELECT id FROM profile_photos WHERE id = ${photoId} AND user_id = ${userId} FOR UPDATE`;
    if (own.length === 0) throw new ProfilePhotoNotFoundError();
    await tx`UPDATE profile_photos SET is_primary = (id = ${photoId}) WHERE user_id = ${userId}`;
  });

  return await getProfilePhotos(userId);
}

// ============ MODULE 2: GESTION EVENTS COMPLÈTE ============

// Add event photo
export async function addEventPhoto(params: {
  eventId: number;
  url: string;
  position?: number;
  isCover?: boolean;
}) {
  const result = await sql`
    INSERT INTO event_photos (event_id, url, position, is_cover)
    VALUES (${params.eventId}, ${params.url}, ${params.position ?? 0}, ${params.isCover ?? false})
    RETURNING *
  `;
  return result[0];
}

// Get event photos
export async function getEventPhotos(eventId: number) {
  const photos = await sql`
    SELECT * FROM event_photos
    WHERE event_id = ${eventId}
    ORDER BY position ASC
  `;
  return photos;
}

// Delete event photo
export async function deleteEventPhoto(photoId: number) {
  await sql`DELETE FROM event_photos WHERE id = ${photoId}`;
}

// Check in attendee
export async function checkInAttendee(params: {
  eventId: number;
  userId: number;
  checkedInBy: string;
}) {
  const result = await sql`
    INSERT INTO event_checkins (event_id, user_id, checked_in_by)
    VALUES (${params.eventId}, ${params.userId}, ${params.checkedInBy})
    ON CONFLICT (event_id, user_id) DO UPDATE SET
      checked_in_at = NOW(),
      checked_in_by = ${params.checkedInBy}
    RETURNING *
  `;
  return result[0];
}

// Get event with full details (admin)
export async function getEventFullDetails(eventId: number) {
  const event = await getEventById(eventId);
  if (!event) return null;

  const photos = await getEventPhotos(eventId);
  const attendees = await sql`
    SELECT
      r.id as rsvp_id,
      r.status,
      r.paid,
      r.created_at as rsvp_at,
      u.id as user_id,
      u.email,
      u.name,
      u.picture,
      p.display_name,
      ec.checked_in_at
    FROM event_rsvps r
    JOIN users u ON u.id = r.user_id
    LEFT JOIN profiles p ON p.user_id = u.id
    LEFT JOIN event_checkins ec ON ec.event_id = r.event_id AND ec.user_id = r.user_id
    WHERE r.event_id = ${eventId}
    ORDER BY r.created_at ASC
  `;

  const checkedInCount = attendees.filter((a: any) => a.checked_in_at).length;

  return {
    ...event,
    photos,
    attendees,
    checkedInCount,
  };
}

// Export event attendees as CSV data
export async function exportEventAttendees(eventId: number) {
  const attendees = await sql`
    SELECT
      u.email,
      u.name,
      p.display_name,
      r.status,
      r.paid,
      r.created_at as rsvp_at,
      ec.checked_in_at
    FROM event_rsvps r
    JOIN users u ON u.id = r.user_id
    LEFT JOIN profiles p ON p.user_id = u.id
    LEFT JOIN event_checkins ec ON ec.event_id = r.event_id AND ec.user_id = r.user_id
    WHERE r.event_id = ${eventId}
    ORDER BY r.created_at ASC
  `;

  return attendees;
}

// Duplicate event
export async function duplicateEvent(eventId: number) {
  const event = await getEventById(eventId);
  if (!event) return null;

  const e = event as any;
  const newEvent = await createEvent({
    title: `${e.title} (copie)`,
    description: e.description,
    eventType: e.event_type,
    location: e.location,
    address: e.address,
    latitude: e.latitude,
    longitude: e.longitude,
    date: e.date,
    time: e.time,
    endTime: e.end_time,
    price: e.price,
    currency: e.currency,
    maxAttendees: e.max_attendees,
    imageUrl: e.image_url,
    isPublished: false,
  });

  // Copy photos
  const photos = await getEventPhotos(eventId);
  for (const photo of photos as any[]) {
    await addEventPhoto({
      eventId: (newEvent as any).id,
      url: photo.url,
      position: photo.position,
      isCover: photo.is_cover,
    });
  }

  return newEvent;
}

// ============ MODULE 3: CAMPAGNES EMAIL/PUSH ============

// Create campaign
export async function createCampaign(params: {
  type: 'email' | 'push';
  title: string;
  subject?: string;
  content: string;
  segmentId?: number;
  scheduledAt?: Date;
  createdBy: string;
}) {
  const result = await sql`
    INSERT INTO campaigns (type, title, subject, content, segment_id, scheduled_at, created_by)
    VALUES (${params.type}, ${params.title}, ${params.subject ?? null}, ${params.content}, ${params.segmentId ?? null}, ${params.scheduledAt ?? null}, ${params.createdBy})
    RETURNING *
  `;
  return result[0];
}

// Statuses a campaign goes through. Only draft and scheduled campaigns can be
// edited or sent; 'sending' is the lock held while a send is running.
export type CampaignStatus = 'draft' | 'scheduled' | 'sending' | 'sent' | 'failed';

export interface CampaignRecord {
  id: number;
  type: 'email' | 'push';
  title: string;
  subject: string | null;
  content: string;
  segment_id: number | null;
  status: CampaignStatus;
}

// Update a campaign that has not been sent yet. Returns undefined when the
// campaign does not exist OR is no longer editable (the caller tells them apart).
export async function updateCampaign(campaignId: number, params: Partial<{
  title: string;
  subject: string;
  content: string;
  segmentId: number;
  scheduledAt: Date;
  status: 'draft' | 'scheduled';
}>) {
  const result = await sql`
    UPDATE campaigns SET
      title = COALESCE(${params.title ?? null}, title),
      subject = COALESCE(${params.subject ?? null}, subject),
      content = COALESCE(${params.content ?? null}, content),
      segment_id = COALESCE(${params.segmentId ?? null}, segment_id),
      scheduled_at = COALESCE(${params.scheduledAt ?? null}, scheduled_at),
      status = COALESCE(${params.status ?? null}, status),
      updated_at = NOW()
    WHERE id = ${campaignId} AND status IN ('draft', 'scheduled')
    RETURNING *
  `;
  return result[0];
}

// Get campaigns
export async function getCampaigns(filters?: {
  status?: string;
  type?: string;
  limit?: number;
  offset?: number;
}) {
  const limit = filters?.limit ?? 50;
  const offset = filters?.offset ?? 0;

  let campaigns;
  if (filters?.status && filters?.type) {
    campaigns = await sql`
      SELECT * FROM campaigns
      WHERE status = ${filters.status} AND type = ${filters.type}
      ORDER BY created_at DESC
      LIMIT ${limit} OFFSET ${offset}
    `;
  } else if (filters?.status) {
    campaigns = await sql`
      SELECT * FROM campaigns
      WHERE status = ${filters.status}
      ORDER BY created_at DESC
      LIMIT ${limit} OFFSET ${offset}
    `;
  } else if (filters?.type) {
    campaigns = await sql`
      SELECT * FROM campaigns
      WHERE type = ${filters.type}
      ORDER BY created_at DESC
      LIMIT ${limit} OFFSET ${offset}
    `;
  } else {
    campaigns = await sql`
      SELECT * FROM campaigns
      ORDER BY created_at DESC
      LIMIT ${limit} OFFSET ${offset}
    `;
  }

  return campaigns;
}

// Get campaign by ID
export async function getCampaignById(campaignId: number) {
  const result = await sql`SELECT * FROM campaigns WHERE id = ${campaignId}`;
  return result.length ? result[0] : null;
}

// Delete campaign
export async function deleteCampaign(campaignId: number) {
  await sql`DELETE FROM campaign_recipients WHERE campaign_id = ${campaignId}`;
  await sql`DELETE FROM campaigns WHERE id = ${campaignId}`;
}

// Get users for campaign (based on segment)
export interface CampaignRecipient {
  id: number;
  email: string;
}

// Segment filters are stored but not evaluated yet. Until they are, a campaign
// tied to a segment must NOT be sent: it used to fall back to every member.
export class SegmentFiltersNotImplementedError extends Error {
  constructor() {
    super('Segment filters are not implemented: refusing to target every member');
    this.name = 'SegmentFiltersNotImplementedError';
  }
}

export async function getCampaignRecipients(segmentId?: number | null): Promise<CampaignRecipient[]> {
  if (segmentId) throw new SegmentFiltersNotImplementedError();

  // All active users
  return await sql<CampaignRecipient[]>`
    SELECT u.id, u.email
    FROM users u
    WHERE u.is_active = true
      AND u.provider NOT IN ('seed', 'review')
      AND u.email NOT IN (SELECT email FROM email_unsubscribes)
    ORDER BY u.created_at DESC
  `;
}

// Take the send lock: draft/scheduled -> sending, in ONE statement, so two
// concurrent sends cannot both win. Returns undefined when the campaign is
// missing, already taken, sent, or tied to a segment.
export async function claimCampaignForSending(campaignId: number) {
  const result = await sql<CampaignRecord[]>`
    UPDATE campaigns
    SET status = 'sending', updated_at = NOW()
    WHERE id = ${campaignId} AND status IN ('draft', 'scheduled') AND segment_id IS NULL
    RETURNING *
  `;
  return result[0];
}

// Record who the campaign is addressed to. Nobody is marked as delivered yet:
// sent_at is only set once the provider accepted the message.
export async function addCampaignRecipients(campaignId: number, recipients: CampaignRecipient[]) {
  if (recipients.length === 0) return;
  const rows = recipients.map((r) => ({ campaign_id: campaignId, user_id: r.id, email: r.email }));
  await sql`INSERT INTO campaign_recipients ${sql(rows)} ON CONFLICT (campaign_id, user_id) DO NOTHING`;
}

export async function markCampaignRecipientsSent(campaignId: number, userIds: number[]) {
  if (userIds.length === 0) return;
  await sql`
    UPDATE campaign_recipients
    SET sent_at = NOW()
    WHERE campaign_id = ${campaignId} AND user_id IN ${sql(userIds)}
  `;
}

// Release the send lock. A campaign nobody received is 'failed', not 'sent'.
export async function finishCampaignSending(campaignId: number, outcome: { sent: number; total: number }) {
  const delivered = outcome.sent > 0 || outcome.total === 0;
  await sql`
    UPDATE campaigns
    SET status = ${delivered ? 'sent' : 'failed'},
        sent_at = ${delivered ? sql`NOW()` : null},
        stats_sent = ${outcome.sent},
        updated_at = NOW()
    WHERE id = ${campaignId} AND status = 'sending'
  `;
}

// Track campaign open
export async function trackCampaignOpen(campaignId: number, userId: number) {
  await sql`
    UPDATE campaign_recipients
    SET opened_at = COALESCE(opened_at, NOW())
    WHERE campaign_id = ${campaignId} AND user_id = ${userId}
  `;

  await sql`
    UPDATE campaigns
    SET stats_opened = stats_opened + 1
    WHERE id = ${campaignId}
  `;
}

// Track campaign click
export async function trackCampaignClick(campaignId: number, userId: number) {
  await sql`
    UPDATE campaign_recipients
    SET clicked_at = COALESCE(clicked_at, NOW())
    WHERE campaign_id = ${campaignId} AND user_id = ${userId}
  `;

  await sql`
    UPDATE campaigns
    SET stats_clicked = stats_clicked + 1
    WHERE id = ${campaignId}
  `;
}

// Create segment
export async function createSegment(params: {
  name: string;
  description?: string;
  filters: object;
  createdBy: string;
}) {
  const result = await sql`
    INSERT INTO user_segments (name, description, filters, created_by)
    VALUES (${params.name}, ${params.description ?? null}, ${JSON.stringify(params.filters)}, ${params.createdBy})
    RETURNING *
  `;
  return result[0];
}

// Get segments
export async function getSegments() {
  return await sql`SELECT * FROM user_segments ORDER BY created_at DESC`;
}

// Unsubscribe email
export async function unsubscribeEmail(email: string) {
  await sql`
    INSERT INTO email_unsubscribes (email)
    VALUES (${email})
    ON CONFLICT (email) DO NOTHING
  `;
}

// ============ MODULE 4: MODÉRATION & SIGNALEMENTS ============

// Create report
export async function createReport(params: {
  reporterId: number;
  reportedUserId: number;
  reason: string;
  details?: string;
}) {
  const result = await sql`
    INSERT INTO reports (reporter_id, reported_user_id, reason, details)
    VALUES (${params.reporterId}, ${params.reportedUserId}, ${params.reason}, ${params.details ?? null})
    RETURNING *
  `;
  return result[0];
}

// ============ USER BLOCKING ============

// Block a user (idempotent). Returns nothing meaningful; conflict is ignored.
export async function blockUser(blockerId: number, blockedId: number): Promise<void> {
  await sql`
    INSERT INTO blocked_users (blocker_id, blocked_id)
    VALUES (${blockerId}, ${blockedId})
    ON CONFLICT (blocker_id, blocked_id) DO NOTHING
  `;
}

// Unblock a user (idempotent).
export async function unblockUser(blockerId: number, blockedId: number): Promise<void> {
  await sql`
    DELETE FROM blocked_users
    WHERE blocker_id = ${blockerId} AND blocked_id = ${blockedId}
  `;
}

// Return the set of user ids that `userId` has blocked OR that have blocked
// `userId` (bidirectional). Used to filter listings both ways.
export async function getBlockedUserIds(userId: number): Promise<Set<number>> {
  const rows = await sql`
    SELECT blocked_id AS other_id FROM blocked_users WHERE blocker_id = ${userId}
    UNION
    SELECT blocker_id AS other_id FROM blocked_users WHERE blocked_id = ${userId}
  `;
  return new Set((rows as unknown as Array<{ other_id: number }>).map((r) => r.other_id));
}

// True when either user has blocked the other.
export async function isBlockedBetween(userA: number, userB: number): Promise<boolean> {
  const rows = await sql`
    SELECT 1 FROM blocked_users
    WHERE (blocker_id = ${userA} AND blocked_id = ${userB})
       OR (blocker_id = ${userB} AND blocked_id = ${userA})
    LIMIT 1
  `;
  return rows.length > 0;
}

// Profiles blocked BY userId (the outgoing block list shown to the user).
// Shape mirrors getMatches/getConversations profile rows.
export async function getBlockedUsers(userId: number): Promise<Array<{
  user_id: number;
  display_name: string | null;
  age: number | null;
  location: string | null;
  is_verified: boolean | null;
  picture: string | null;
  blocked_at: Date;
}>> {
  const rows = await sql`
    SELECT
      b.blocked_id AS user_id,
      p.display_name,
      DATE_PART('year', AGE(p.birthdate)) AS age,
      p.location,
      ${badgeColumns(sql)},
      u.picture,
      ${primaryPhotoColumns(sql)},
      b.created_at AS blocked_at
    FROM blocked_users b
    JOIN users u ON u.id = b.blocked_id
    LEFT JOIN profiles p ON p.user_id = b.blocked_id
    WHERE b.blocker_id = ${userId}
    ORDER BY b.created_at DESC
  `;
  return rows.map((row) => withPublicPicture(row as any)) as unknown as Array<{
    user_id: number;
    display_name: string | null;
    age: number | null;
    location: string | null;
    is_verified: boolean | null;
    picture: string | null;
    blocked_at: Date;
  }>;
}

// Get reports (admin moderation).
//
// RETENTION CHOICE: `reported_message_content` is the ONLY place where the text
// of a reported message can be read after its author unsent it. Unsending
// normally empties the text in the database; when a report points at the
// message the text is kept, so that a harasser cannot erase the evidence by
// unsending. Every route used by members (history, conversation list, WebSocket
// events, the unsend answer) hides it behind `unsent: true`. The text lives as
// long as its conversation: deleting the account or the conversation removes it.
export async function getReports(filters?: {
  status?: string;
  limit?: number;
  offset?: number;
}) {
  const limit = filters?.limit ?? 50;
  const offset = filters?.offset ?? 0;

  if (filters?.status) {
    return await sql`
      SELECT r.*,
        reporter.email as reporter_email,
        reporter.name as reporter_name,
        reported.email as reported_email,
        reported.name as reported_name,
        p.display_name as reported_display_name,
        rm.content as reported_message_content,
        (rm.unsent_at IS NOT NULL) as reported_message_unsent
      FROM reports r
      LEFT JOIN users reporter ON reporter.id = r.reporter_id
      LEFT JOIN users reported ON reported.id = r.reported_user_id
      LEFT JOIN profiles p ON p.user_id = r.reported_user_id
      LEFT JOIN messages rm ON rm.id = r.message_id
      WHERE r.status = ${filters.status}
      ORDER BY r.created_at DESC
      LIMIT ${limit} OFFSET ${offset}
    `;
  }

  return await sql`
    SELECT r.*,
      reporter.email as reporter_email,
      reporter.name as reporter_name,
      reported.email as reported_email,
      reported.name as reported_name,
      p.display_name as reported_display_name,
      rm.content as reported_message_content,
      (rm.unsent_at IS NOT NULL) as reported_message_unsent
    FROM reports r
    LEFT JOIN users reporter ON reporter.id = r.reporter_id
    LEFT JOIN users reported ON reported.id = r.reported_user_id
    LEFT JOIN profiles p ON p.user_id = r.reported_user_id
    LEFT JOIN messages rm ON rm.id = r.message_id
    ORDER BY r.created_at DESC
    LIMIT ${limit} OFFSET ${offset}
  `;
}

// Handle report
export async function handleReport(params: {
  reportId: number;
  handledBy: string;
  actionTaken: string;
  status?: string;
}) {
  const result = await sql`
    UPDATE reports
    SET status = ${params.status ?? 'handled'},
        handled_by = ${params.handledBy},
        handled_at = NOW(),
        action_taken = ${params.actionTaken}
    WHERE id = ${params.reportId}
    RETURNING *
  `;

  // Log action
  await logModerationAction({
    adminEmail: params.handledBy,
    action: 'handle_report',
    targetType: 'report',
    targetId: params.reportId,
    details: { actionTaken: params.actionTaken },
  });

  return result[0];
}

// Add photo to moderation queue
export async function addPhotoToModeration(params: {
  photoId?: number;
  userId: number;
  photoUrl: string;
}) {
  const result = await sql`
    INSERT INTO photo_moderation (photo_id, user_id, photo_url)
    VALUES (${params.photoId ?? null}, ${params.userId}, ${params.photoUrl})
    RETURNING *
  `;
  return result[0];
}

// Get pending photos for moderation
export async function getPendingPhotos(limit = 50) {
  return await sql`
    SELECT pm.*,
      u.email,
      u.name,
      p.display_name
    FROM photo_moderation pm
    JOIN users u ON u.id = pm.user_id
    LEFT JOIN profiles p ON p.user_id = pm.user_id
    WHERE pm.status = 'pending'
    ORDER BY pm.created_at ASC
    LIMIT ${limit}
  `;
}

// Approve photo
export async function approvePhoto(photoId: number, reviewedBy: string) {
  await sql`
    UPDATE photo_moderation
    SET status = 'approved', reviewed_by = ${reviewedBy}, reviewed_at = NOW()
    WHERE id = ${photoId}
  `;

  await logModerationAction({
    adminEmail: reviewedBy,
    action: 'approve_photo',
    targetType: 'photo',
    targetId: photoId,
  });
}

// Reject photo
export async function rejectPhoto(photoId: number, reviewedBy: string, reason: string) {
  await sql`
    UPDATE photo_moderation
    SET status = 'rejected', reviewed_by = ${reviewedBy}, reviewed_at = NOW(), rejection_reason = ${reason}
    WHERE id = ${photoId}
  `;

  await logModerationAction({
    adminEmail: reviewedBy,
    action: 'reject_photo',
    targetType: 'photo',
    targetId: photoId,
    details: { reason },
  });
}

// Log moderation action
export async function logModerationAction(params: {
  adminEmail: string;
  action: string;
  targetType: string;
  targetId?: number;
  details?: object;
}) {
  await sql`
    INSERT INTO moderation_logs (admin_email, action, target_type, target_id, details)
    VALUES (${params.adminEmail}, ${params.action}, ${params.targetType}, ${params.targetId ?? null}, ${params.details ? JSON.stringify(params.details) : null})
  `;
}

// Get moderation logs
export async function getModerationLogs(filters?: {
  adminEmail?: string;
  targetType?: string;
  limit?: number;
  offset?: number;
}) {
  const limit = filters?.limit ?? 100;
  const offset = filters?.offset ?? 0;

  if (filters?.adminEmail) {
    return await sql`
      SELECT * FROM moderation_logs
      WHERE admin_email = ${filters.adminEmail}
      ORDER BY created_at DESC
      LIMIT ${limit} OFFSET ${offset}
    `;
  }

  if (filters?.targetType) {
    return await sql`
      SELECT * FROM moderation_logs
      WHERE target_type = ${filters.targetType}
      ORDER BY created_at DESC
      LIMIT ${limit} OFFSET ${offset}
    `;
  }

  return await sql`
    SELECT * FROM moderation_logs
    ORDER BY created_at DESC
    LIMIT ${limit} OFFSET ${offset}
  `;
}

// Get report counts for dashboard
export async function getReportStats() {
  const result = await sql`
    SELECT
      COUNT(*) FILTER (WHERE status = 'pending') as pending,
      COUNT(*) FILTER (WHERE status = 'handled') as handled,
      COUNT(*) FILTER (WHERE status = 'dismissed') as dismissed,
      COUNT(*) as total
    FROM reports
  `;
  return result[0];
}

// ============ COUPLE MODE FUNCTIONS ============

// Get couple activities feed
export async function getCoupleActivities(coupleId: number, limit = 20, offset = 0, category?: string) {
  if (category) {
    return await sql`
      SELECT ca.* FROM couple_activities ca
      WHERE ca.is_active = true
        AND ca.category = ${category}
        AND ca.id NOT IN (
          SELECT activity_id FROM couple_passed_activities WHERE couple_id = ${coupleId}
        )
        AND ca.id NOT IN (
          SELECT activity_id FROM couple_saved_activities WHERE couple_id = ${coupleId}
        )
      ORDER BY ca.is_partner DESC, ca.rating DESC NULLS LAST, RANDOM()
      LIMIT ${limit} OFFSET ${offset}
    `;
  }

  return await sql`
    SELECT ca.* FROM couple_activities ca
    WHERE ca.is_active = true
      AND ca.id NOT IN (
        SELECT activity_id FROM couple_passed_activities WHERE couple_id = ${coupleId}
      )
      AND ca.id NOT IN (
        SELECT activity_id FROM couple_saved_activities WHERE couple_id = ${coupleId}
      )
    ORDER BY ca.is_partner DESC, ca.rating DESC NULLS LAST, RANDOM()
    LIMIT ${limit} OFFSET ${offset}
  `;
}

// Get single activity
export async function getCoupleActivity(activityId: number) {
  const result = await sql`
    SELECT * FROM couple_activities WHERE id = ${activityId} AND is_active = true
  `;
  return result.length ? result[0] : null;
}

// Save activity (bookmark)
export async function saveCoupleActivity(coupleId: number, activityId: number, notes?: string) {
  return await sql`
    INSERT INTO couple_saved_activities (couple_id, activity_id, notes)
    VALUES (${coupleId}, ${activityId}, ${notes ?? null})
    ON CONFLICT (couple_id, activity_id) DO UPDATE SET notes = COALESCE(${notes ?? null}, couple_saved_activities.notes)
    RETURNING *
  `;
}

// Pass activity (swipe left)
export async function passCoupleActivity(coupleId: number, activityId: number) {
  return await sql`
    INSERT INTO couple_passed_activities (couple_id, activity_id)
    VALUES (${coupleId}, ${activityId})
    ON CONFLICT (couple_id, activity_id) DO NOTHING
    RETURNING *
  `;
}

// Get saved activities
export async function getSavedActivities(coupleId: number) {
  return await sql`
    SELECT ca.*, csa.saved_at, csa.notes as user_notes
    FROM couple_activities ca
    JOIN couple_saved_activities csa ON csa.activity_id = ca.id
    WHERE csa.couple_id = ${coupleId}
    ORDER BY csa.saved_at DESC
  `;
}

// Remove saved activity
export async function removeSavedActivity(coupleId: number, activityId: number) {
  return await sql`
    DELETE FROM couple_saved_activities
    WHERE couple_id = ${coupleId} AND activity_id = ${activityId}
    RETURNING *
  `;
}

export type CoupleBookingResult =
  | { ok: true; booking: Array<Record<string, unknown>> }
  | { ok: false; status: 402 | 404 | 409; error: string };

type BookableEvent = { price_cents: number | null; is_past: boolean };

// Why an event cannot be taken (booked or joined) right now, or null when it can.
// `paid` is true when this couple already paid for it.
function eventRefusal(event: BookableEvent | undefined, paid: boolean): { status: 402 | 404 | 409; error: string } | null {
  if (!event) return { status: 404, error: 'Event not found' };
  if (event.is_past) return { status: 409, error: 'Event is over' };
  if ((event.price_cents ?? 0) > 0 && !paid) {
    return { status: 402, error: 'This event is paid: payment is required before registering' };
  }
  return null;
}

// Create booking. Only a published, upcoming, free event (or an active
// activity) can be booked: a draft, past or paid event is refused.
export async function createCoupleBooking(params: {
  coupleId: number;
  activityId?: number | null;
  eventId?: number | null;
  bookingDate: string;
  bookingTime?: string | null;
  notes?: string | null;
}): Promise<CoupleBookingResult> {
  if (params.eventId != null) {
    const [event] = await sql<(BookableEvent & { id: number })[]>`
      SELECT id, price_cents, event_date < CURRENT_DATE AS is_past
      FROM couple_events WHERE id = ${params.eventId} AND is_published = true
    `;
    const refusal = eventRefusal(event, false);
    if (refusal) return { ok: false, ...refusal };
  }
  if (params.activityId != null) {
    const activity = await sql`
      SELECT 1 FROM couple_activities WHERE id = ${params.activityId} AND is_active = true
    `;
    if (activity.length === 0) return { ok: false, status: 404, error: 'Activity not found' };
  }

  const booking = await sql`
    INSERT INTO couple_bookings (couple_id, activity_id, event_id, booking_date, booking_time, notes, status)
    VALUES (${params.coupleId}, ${params.activityId ?? null}, ${params.eventId ?? null}, ${params.bookingDate}, ${params.bookingTime ?? null}, ${params.notes ?? null}, 'confirmed')
    RETURNING *
  `;
  return { ok: true, booking: booking as unknown as Array<Record<string, unknown>> };
}

// Get couple bookings
export async function getCoupleBookings(coupleId: number) {
  return await sql`
    SELECT cb.*, ca.title as activity_title, ca.image_url as activity_image, ca.location as activity_location
    FROM couple_bookings cb
    LEFT JOIN couple_activities ca ON ca.id = cb.activity_id
    WHERE cb.couple_id = ${coupleId}
    ORDER BY cb.booking_date DESC
  `;
}

// ============ COUPLE EVENTS ============

// Get couple events
export async function getCoupleEvents(limit = 20, offset = 0, category?: string) {
  if (category) {
    return await sql`
      SELECT * FROM couple_events
      WHERE is_published = true AND event_date >= CURRENT_DATE AND category = ${category}
      ORDER BY is_featured DESC, event_date ASC
      LIMIT ${limit} OFFSET ${offset}
    `;
  }

  return await sql`
    SELECT * FROM couple_events
    WHERE is_published = true AND event_date >= CURRENT_DATE
    ORDER BY is_featured DESC, event_date ASC
    LIMIT ${limit} OFFSET ${offset}
  `;
}

// Get single couple event
export async function getCoupleEvent(eventId: number) {
  const result = await sql`
    SELECT * FROM couple_events WHERE id = ${eventId} AND is_published = true
  `;
  return result.length ? result[0] : null;
}

export type CoupleEventRegistrationResult =
  | { ok: true; registration: Record<string, unknown> }
  | { ok: false; status: 402 | 404 | 409; error: string };

// Register for couple event. The event row is locked for the whole
// transaction, so the checks (published, upcoming, free or paid for, room left)
// and the place taken cannot be interleaved with another registration.
export async function registerForCoupleEvent(
  coupleId: number,
  eventId: number
): Promise<CoupleEventRegistrationResult> {
  return await sql.begin(async (transaction) => {
    const tx = transaction as unknown as typeof sql;
    const [event] = await tx<(BookableEvent & { id: number })[]>`
      SELECT id, price_cents, event_date < CURRENT_DATE AS is_past
      FROM couple_events WHERE id = ${eventId} AND is_published = true
      FOR UPDATE
    `;
    const [existing] = await tx<{ status: string; paid: boolean | null }[]>`
      SELECT status, paid FROM couple_event_registrations
      WHERE couple_id = ${coupleId} AND event_id = ${eventId}
    `;
    const refusal = eventRefusal(event, existing?.paid === true);
    if (refusal) return { ok: false, ...refusal } as const;

    // The count moves only when the registration actually changes state: a
    // second "register" (or a second "cancel") must not count the couple twice.
    // Capacity is checked in the same UPDATE, so two couples cannot both take
    // the last place.
    if (existing?.status !== 'registered') {
      const seat = await tx`
        UPDATE couple_events SET current_couples = current_couples + 1
        WHERE id = ${eventId} AND (max_couples IS NULL OR current_couples < max_couples)
        RETURNING id
      `;
      if (seat.length === 0) return { ok: false, status: 409, error: 'Event is full' } as const;
    }
    const registration = await tx`
      INSERT INTO couple_event_registrations (couple_id, event_id)
      VALUES (${coupleId}, ${eventId})
      ON CONFLICT (couple_id, event_id) DO UPDATE SET status = 'registered', cancelled_at = NULL
      RETURNING *
    `;
    return { ok: true, registration: registration[0] as Record<string, unknown> } as const;
  });
}

// Cancel registration
export async function cancelCoupleEventRegistration(coupleId: number, eventId: number) {
  return await sql.begin(async (transaction) => {
    const tx = transaction as unknown as typeof sql;
    // Only a registration that is still active frees a place.
    const result = await tx`
      UPDATE couple_event_registrations
      SET status = 'cancelled', cancelled_at = NOW()
      WHERE couple_id = ${coupleId} AND event_id = ${eventId} AND status = 'registered'
      RETURNING *
    `;
    if (result.length > 0) {
      await tx`
        UPDATE couple_events SET current_couples = GREATEST(0, current_couples - 1) WHERE id = ${eventId}
      `;
    }
    return result[0];
  });
}

// Get couple's registered events
export async function getCoupleRegisteredEvents(coupleId: number) {
  return await sql`
    SELECT ce.*, cer.registered_at, cer.status as registration_status
    FROM couple_events ce
    JOIN couple_event_registrations cer ON cer.event_id = ce.id
    WHERE cer.couple_id = ${coupleId} AND cer.status = 'registered'
    ORDER BY ce.event_date ASC
  `;
}

// ============ COUPLE MEMORIES ============

// Add memory
export async function addCoupleMemory(params: {
  coupleId: number;
  type: string;
  title?: string;
  content?: string;
  imageUrl?: string;
  memoryDate?: string;
  location?: string;
  createdBy: number;
}) {
  return await sql`
    INSERT INTO couple_memories (couple_id, type, title, content, image_url, memory_date, location, created_by)
    VALUES (${params.coupleId}, ${params.type}, ${params.title ?? null}, ${params.content ?? null}, ${params.imageUrl ?? null}, ${params.memoryDate ?? null}, ${params.location ?? null}, ${params.createdBy})
    RETURNING *
  `;
}

// Get memories
export async function getCoupleMemories(coupleId: number, limit = 50) {
  return await sql`
    SELECT * FROM couple_memories
    WHERE couple_id = ${coupleId}
    ORDER BY COALESCE(memory_date, created_at::date) DESC
    LIMIT ${limit}
  `;
}

// Delete memory
export async function deleteCoupleMemory(coupleId: number, memoryId: number) {
  return await sql`
    DELETE FROM couple_memories WHERE id = ${memoryId} AND couple_id = ${coupleId}
    RETURNING *
  `;
}

// ============ COUPLE DATES ============

// Add important date
export async function addCoupleDate(params: {
  coupleId: number;
  title: string;
  date: string;
  type: string;
  isRecurring?: boolean;
  remindDaysBefore?: number;
  notes?: string;
}) {
  return await sql`
    INSERT INTO couple_dates (couple_id, title, date, type, is_recurring, remind_days_before, notes)
    VALUES (${params.coupleId}, ${params.title}, ${params.date}, ${params.type}, ${params.isRecurring ?? true}, ${params.remindDaysBefore ?? 7}, ${params.notes ?? null})
    RETURNING *
  `;
}

// Get couple dates
export async function getCoupleDates(coupleId: number) {
  return await sql`
    SELECT * FROM couple_dates
    WHERE couple_id = ${coupleId}
    ORDER BY date ASC
  `;
}

// Update couple date
export async function updateCoupleDate(coupleId: number, dateId: number, params: {
  title?: string;
  date?: string;
  notes?: string;
  remindDaysBefore?: number;
}) {
  return await sql`
    UPDATE couple_dates
    SET
      title = COALESCE(${params.title ?? null}, title),
      date = COALESCE(${params.date ?? null}, date),
      notes = COALESCE(${params.notes ?? null}, notes),
      remind_days_before = COALESCE(${params.remindDaysBefore ?? null}, remind_days_before)
    WHERE id = ${dateId} AND couple_id = ${coupleId}
    RETURNING *
  `;
}

// Delete couple date
export async function deleteCoupleDate(coupleId: number, dateId: number) {
  return await sql`
    DELETE FROM couple_dates WHERE id = ${dateId} AND couple_id = ${coupleId}
    RETURNING *
  `;
}

// ============ COUPLE BUCKET LIST ============

// Add bucket list item
export async function addBucketListItem(params: {
  coupleId: number;
  title: string;
  description?: string;
  category?: string;
  targetDate?: string;
}) {
  return await sql`
    INSERT INTO couple_bucket_list (couple_id, title, description, category, target_date)
    VALUES (${params.coupleId}, ${params.title}, ${params.description ?? null}, ${params.category ?? null}, ${params.targetDate ?? null})
    RETURNING *
  `;
}

// Get bucket list
export async function getBucketList(coupleId: number) {
  return await sql`
    SELECT * FROM couple_bucket_list
    WHERE couple_id = ${coupleId}
    ORDER BY is_completed ASC, priority DESC, created_at DESC
  `;
}

// Complete bucket list item
export async function completeBucketListItem(coupleId: number, itemId: number) {
  return await sql`
    UPDATE couple_bucket_list
    SET is_completed = true, completed_at = NOW()
    WHERE id = ${itemId} AND couple_id = ${coupleId}
    RETURNING *
  `;
}

// Delete bucket list item
export async function deleteBucketListItem(coupleId: number, itemId: number) {
  return await sql`
    DELETE FROM couple_bucket_list WHERE id = ${itemId} AND couple_id = ${coupleId}
    RETURNING *
  `;
}

// ============ COUPLE STATS ============

// Get couple stats
export async function getCoupleStats(coupleId: number) {
  const stats = await sql`
    SELECT
      (SELECT COUNT(*) FROM couple_bookings WHERE couple_id = ${coupleId}) as total_bookings,
      (SELECT COUNT(*) FROM couple_saved_activities WHERE couple_id = ${coupleId}) as saved_activities,
      (SELECT COUNT(*) FROM couple_event_registrations WHERE couple_id = ${coupleId} AND status = 'registered') as events_registered,
      (SELECT COUNT(*) FROM couple_memories WHERE couple_id = ${coupleId}) as memories_count,
      (SELECT COUNT(*) FROM couple_bucket_list WHERE couple_id = ${coupleId} AND is_completed = true) as bucket_completed,
      (SELECT COUNT(*) FROM couple_bucket_list WHERE couple_id = ${coupleId}) as bucket_total
  `;
  return stats[0];
}

// Get couple achievements
export async function getCoupleAchievements(coupleId: number) {
  return await sql`
    SELECT * FROM couple_achievements
    WHERE couple_id = ${coupleId}
    ORDER BY unlocked_at DESC
  `;
}

// Unlock achievement
export async function unlockAchievement(coupleId: number, achievementType: string, achievementName: string, description?: string, icon?: string) {
  return await sql`
    INSERT INTO couple_achievements (couple_id, achievement_type, achievement_name, description, icon)
    VALUES (${coupleId}, ${achievementType}, ${achievementName}, ${description ?? null}, ${icon ?? null})
    ON CONFLICT (couple_id, achievement_type) DO NOTHING
    RETURNING *
  `;
}

// ============ SEED COUPLE DATA ============

export async function seedCoupleActivities() {
  // Check if already seeded
  const existing = await sql`SELECT COUNT(*) as count FROM couple_activities`;
  if ((existing[0] as any).count > 0) {
    console.log("Couple activities already seeded");
    return;
  }

  const activities = COUPLE_ACTIVITY_SEEDS;

  for (const activity of activities) {
    await sql`
      INSERT INTO couple_activities (title, description, category, subcategory, image_url, price_cents, location, address, city, rating, review_count, duration_minutes, is_partner, is_kosher, discount_percent, tags)
      VALUES (${activity.title}, ${activity.description}, ${activity.category}, ${activity.subcategory ?? null}, ${activity.image_url}, ${activity.price_cents}, ${activity.location}, ${activity.address ?? null}, ${activity.city}, ${activity.rating}, ${activity.review_count}, ${activity.duration_minutes}, ${activity.is_partner ?? false}, ${activity.is_kosher ?? false}, ${activity.discount_percent ?? null}, ${JSON.stringify(activity.tags)})
    `;
  }

  console.log(`Seeded ${activities.length} couple activities`);
}

export async function seedCoupleEvents() {
  // Check if already seeded
  const existing = await sql`SELECT COUNT(*) as count FROM couple_events`;
  if ((existing[0] as any).count > 0) {
    console.log("Couple events already seeded");
    return;
  }

  const events = COUPLE_EVENT_SEEDS;

  for (const event of events) {
    await sql`
      INSERT INTO couple_events (title, description, category, image_url, event_date, event_time, end_time, location, address, city, price_cents, max_couples, is_kosher, dress_code, what_included, is_featured)
      VALUES (${event.title}, ${event.description}, ${event.category}, ${event.image_url}, ${event.event_date}, ${event.event_time}, ${event.end_time ?? null}, ${event.location}, ${event.address ?? null}, ${event.city}, ${event.price_cents}, ${event.max_couples}, ${event.is_kosher ?? false}, ${event.dress_code ?? null}, ${event.what_included ?? null}, ${event.is_featured ?? false})
    `;
  }

  console.log(`Seeded ${events.length} couple events`);
}
