import postgres from "postgres";

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

  // Add new columns if they don't exist
  await sql`ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false`;
  await sql`ALTER TABLE profiles ADD COLUMN IF NOT EXISTS verification_level VARCHAR(20) DEFAULT 'none'`;

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

  // Subscriptions table (sync with RevenueCat)
  await sql`
    CREATE TABLE IF NOT EXISTS subscriptions (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id) UNIQUE,
      plan_type VARCHAR(50),
      status VARCHAR(20) DEFAULT 'active',
      revenuecat_id VARCHAR(255),
      started_at TIMESTAMP,
      expires_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `;

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

  console.log("Database initialized");

  // Seed fake profiles if empty
  await seedFakeProfiles();

  // Seed couple mode data
  await seedCoupleActivities();
  await seedCoupleEvents();
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

export async function upsertWaitlistAndGetVerification(email: string) {
  const verificationToken = generateVerificationToken();

  const result = await sql`
    INSERT INTO waitlist (email, token, status, confirmed_at, verification_token, verification_status, verification_requested_at)
    VALUES (${email}, ${crypto.randomUUID()}, 'confirmed', NOW(), ${verificationToken}, 'pending', NOW())
    ON CONFLICT (email)
    DO UPDATE SET
      verification_token = ${verificationToken},
      verification_status = 'pending',
      verification_requested_at = NOW()
    RETURNING id, email, verification_token
  `;

  const row = result[0];
  if (!row) throw new Error("Failed to upsert waitlist");

  return { id: row.id as number, email: row.email as string, verificationToken: row.verification_token as string };
}

export async function markVerificationSubmitted(waitlistId: number) {
  await sql`
    UPDATE waitlist
    SET verification_status = 'submitted', documents_submitted_at = NOW()
    WHERE id = ${waitlistId}
  `;
}

export async function findWaitlistByVerificationToken(token: string) {
  const result = await sql`
    SELECT id, email, verification_status FROM waitlist WHERE verification_token = ${token}
  `;
  return result.length ? (result[0] as { id: number; email: string; verification_status: string }) : null;
}

export async function createDocument(params: {
  waitlistId: number;
  type: string;
  filename: string;
  originalName?: string;
  mimeType?: string;
}) {
  const result = await sql`
    INSERT INTO documents (waitlist_id, type, filename, original_name, mime_type)
    VALUES (${params.waitlistId}, ${params.type}, ${params.filename}, ${params.originalName ?? null}, ${params.mimeType ?? null})
    RETURNING id
  `;
  const row = result[0];
  if (!row) throw new Error("Failed to create document");
  return row.id as number;
}

export async function listVerifiedProfiles() {
  const rows = await sql`
    SELECT w.id as waitlist_id, w.email, w.verification_status, w.verified_at, w.os,
           d.id as document_id, d.type, d.filename, d.mime_type, d.status as document_status, d.created_at
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
        filename: row.filename,
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
           d.id as document_id, d.type, d.filename, d.mime_type, d.status as document_status, d.created_at
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
        filename: row.filename,
        mimeType: row.mime_type,
        status: row.document_status,
        createdAt: row.created_at,
      });
    }
  }

  return Array.from(grouped.values());
}

export async function setDocumentReview(params: { documentId: number; status: 'approved' | 'rejected'; notes?: string }) {
  await sql`
    UPDATE documents
    SET status = ${params.status}, reviewed_at = NOW(), reviewer_notes = ${params.notes ?? null}
    WHERE id = ${params.documentId}
  `;
}

export async function setDocumentsReviewBulk(params: {
  waitlistId: number;
  documentIds: number[];
  status: 'approved' | 'rejected';
  notes?: string;
}) {
  if (!params.documentIds.length) return;

  await sql`
    UPDATE documents
    SET status = ${params.status}, reviewed_at = NOW(), reviewer_notes = ${params.notes ?? null}
    WHERE waitlist_id = ${params.waitlistId} AND id IN ${sql(params.documentIds)}
  `;
}

export async function getDocumentTypesByIds(params: { waitlistId: number; documentIds: number[] }) {
  if (!params.documentIds.length) return [] as string[];

  const rows = await sql`
    SELECT id, type
    FROM documents
    WHERE waitlist_id = ${params.waitlistId} AND id IN ${sql(params.documentIds)}
  `;

  return (rows as any[]).map((r) => r.type as string);
}

export async function getWaitlistEmailById(waitlistId: number) {
  const rows = await sql`
    SELECT email FROM waitlist WHERE id = ${waitlistId}
  `;
  const row = rows[0];
  return row ? (row.email as string) : null;
}

export async function getDocumentById(documentId: number) {
  const result = await sql`
    SELECT id, waitlist_id, filename, mime_type FROM documents WHERE id = ${documentId}
  `;
  return result.length
    ? (result[0] as { id: number; waitlist_id: number; filename: string; mime_type: string | null })
    : null;
}

export async function getLatestDocumentsByType(waitlistId: number) {
  const rows = await sql`
    SELECT DISTINCT ON (type)
      id, type, filename, mime_type, status, created_at
    FROM documents
    WHERE waitlist_id = ${waitlistId}
    ORDER BY type, created_at DESC
  `;

  const map: Record<
    string,
    { id: number; type: string; filename: string; mimeType: string | null; status: string }
  > = {};

  for (const row of rows as any[]) {
    map[row.type] = {
      id: row.id,
      type: row.type,
      filename: row.filename,
      mimeType: row.mime_type ?? null,
      status: row.status,
    };
  }

  return map;
}

export async function approveAllDocumentsForWaitlist(waitlistId: number) {
  await sql`
    UPDATE documents
    SET status = 'approved', reviewed_at = NOW(), reviewer_notes = NULL
    WHERE waitlist_id = ${waitlistId} AND status != 'rejected'
  `;
}

export async function rejectAllDocumentsForWaitlist(waitlistId: number, notes?: string) {
  await sql`
    UPDATE documents
    SET status = 'rejected', reviewed_at = NOW(), reviewer_notes = ${notes ?? null}
    WHERE waitlist_id = ${waitlistId}
  `;
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

export async function getFullProfile(userId: number) {
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
      p.is_verified,
      p.verification_level,
      u.picture,
      u.name,
      u.email
    FROM profiles p
    JOIN users u ON u.id = p.user_id
    WHERE p.user_id = ${userId}
  `;

  if (result.length === 0) return null;

  const profile = result[0] as any;

  // Get photos
  const photos = await sql`
    SELECT url, position FROM profile_photos
    WHERE user_id = ${userId}
    ORDER BY position ASC
  `;

  return {
    ...profile,
    photos: photos.length > 0 ? photos.map((p: any) => p.url) : (profile.picture ? [profile.picture] : []),
  };
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
}) {
  const result = await sql`
    INSERT INTO profiles (user_id, display_name, birthdate, gender, bio, location, latitude, longitude, denomination, kashrut_level, shabbat_observance, looking_for, age_min, age_max, distance_max)
    VALUES (
      ${userId},
      ${params.displayName ?? null},
      ${params.birthdate ?? null},
      ${params.gender ?? null},
      ${params.bio ?? null},
      ${params.location ?? null},
      ${params.latitude ?? null},
      ${params.longitude ?? null},
      ${params.denomination ?? null},
      ${params.kashrutLevel ?? null},
      ${params.shabbatObservance ?? null},
      ${params.lookingFor ?? null},
      ${params.ageMin ?? 18},
      ${params.ageMax ?? 99},
      ${params.distanceMax ?? 100}
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
      display_name = COALESCE(${params.displayName ?? null}, profiles.display_name),
      birthdate = COALESCE(${params.birthdate ?? null}, profiles.birthdate),
      gender = COALESCE(${params.gender ?? null}, profiles.gender),
      bio = COALESCE(${params.bio ?? null}, profiles.bio),
      location = COALESCE(${params.location ?? null}, profiles.location),
      latitude = COALESCE(${params.latitude ?? null}, profiles.latitude),
      longitude = COALESCE(${params.longitude ?? null}, profiles.longitude),
      denomination = COALESCE(${params.denomination ?? null}, profiles.denomination),
      kashrut_level = COALESCE(${params.kashrutLevel ?? null}, profiles.kashrut_level),
      shabbat_observance = COALESCE(${params.shabbatObservance ?? null}, profiles.shabbat_observance),
      looking_for = COALESCE(${params.lookingFor ?? null}, profiles.looking_for),
      age_min = COALESCE(${params.ageMin ?? null}, profiles.age_min),
      age_max = COALESCE(${params.ageMax ?? null}, profiles.age_max),
      distance_max = COALESCE(${params.distanceMax ?? null}, profiles.distance_max),
      updated_at = NOW()
    RETURNING *
  `;
  return result[0];
}

// ============ DISCOVER & SWIPES ============

export async function getDiscoverProfiles(userId: number, limit = 20, offset = 0) {
  // Get profiles that the user hasn't swiped on yet
  const profiles = await sql`
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
      p.is_verified,
      p.verification_level,
      u.picture
    FROM profiles p
    JOIN users u ON u.id = p.user_id
    WHERE p.user_id != ${userId}
      AND p.is_complete = true
      AND p.user_id NOT IN (
        SELECT target_user_id FROM swipes WHERE user_id = ${userId}
      )
    ORDER BY p.created_at DESC
    LIMIT ${limit}
    OFFSET ${offset}
  `;

  // Get photos for each profile
  const userIds = profiles.map((p: any) => p.user_id);
  const photos = userIds.length > 0 ? await sql`
    SELECT user_id, url, position FROM profile_photos
    WHERE user_id IN ${sql(userIds)}
    ORDER BY position ASC
  ` : [];

  const photoMap = new Map<number, string[]>();
  for (const photo of photos as any[]) {
    if (!photoMap.has(photo.user_id)) {
      photoMap.set(photo.user_id, []);
    }
    photoMap.get(photo.user_id)!.push(photo.url);
  }

  return profiles.map((p: any) => ({
    ...p,
    photos: photoMap.get(p.user_id) || (p.picture ? [p.picture] : []),
  }));
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
    WHERE m.user1_id = ${userId} OR m.user2_id = ${userId}
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
      p.is_verified,
      u.picture
    FROM profiles p
    JOIN users u ON u.id = p.user_id
    WHERE p.user_id IN ${sql(otherUserIds)}
  `;

  const profileMap = new Map<number, any>();
  for (const p of profiles as any[]) {
    profileMap.set(p.user_id, p);
  }

  return matches.map((m: any) => ({
    matchId: m.match_id,
    matchedAt: m.matched_at,
    conversationId: m.conversation_id,
    profile: profileMap.get(m.other_user_id),
  }));
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
    const birthYear = new Date().getFullYear() - p.age;
    const birthdate = `${birthYear}-06-15`;

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
        ${p.name.split(' ')[0]},
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
    const birthYear = new Date().getFullYear() - p.age;
    const birthdate = `${birthYear}-06-15`;

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
        ${p.name.split(' ')[0]},
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
        SELECT content FROM messages
        WHERE conversation_id = c.id
        ORDER BY created_at DESC
        LIMIT 1
      ) as last_message,
      (
        SELECT COUNT(*) FROM messages
        WHERE conversation_id = c.id
        AND sender_id != ${userId}
        AND is_read = false
      ) as unread_count
    FROM conversations c
    WHERE c.user1_id = ${userId} OR c.user2_id = ${userId}
    ORDER BY COALESCE(c.last_message_at, c.created_at) DESC
  `;

  if (conversations.length === 0) return [];

  const otherUserIds = conversations.map((c: any) => c.other_user_id);
  const profiles = await sql`
    SELECT
      p.user_id,
      p.display_name,
      p.is_verified,
      u.picture
    FROM profiles p
    JOIN users u ON u.id = p.user_id
    WHERE p.user_id IN ${sql(otherUserIds)}
  `;

  const profileMap = new Map<number, any>();
  for (const p of profiles as any[]) {
    profileMap.set(p.user_id, p);
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

export async function getMessages(conversationId: number, limit = 50, offset = 0) {
  const messages = await sql`
    SELECT
      m.id,
      m.sender_id,
      m.content,
      m.is_read,
      m.created_at
    FROM messages m
    WHERE m.conversation_id = ${conversationId}
    ORDER BY m.created_at DESC
    LIMIT ${limit}
    OFFSET ${offset}
  `;
  // Return in DESC order (newest first) for Flutter's reverse ListView
  return messages;
}

export async function createMessage(conversationId: number, senderId: number, content: string) {
  const result = await sql`
    INSERT INTO messages (conversation_id, sender_id, content)
    VALUES (${conversationId}, ${senderId}, ${content})
    RETURNING *
  `;

  // Update last_message_at
  await sql`
    UPDATE conversations
    SET last_message_at = NOW()
    WHERE id = ${conversationId}
  `;

  return result[0];
}

export async function markMessagesAsRead(conversationId: number, userId: number) {
  await sql`
    UPDATE messages
    SET is_read = true
    WHERE conversation_id = ${conversationId}
    AND sender_id != ${userId}
    AND is_read = false
  `;
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

export async function createRsvp(eventId: number, userId: number, status = 'going') {
  const result = await sql`
    INSERT INTO event_rsvps (event_id, user_id, status)
    VALUES (${eventId}, ${userId}, ${status})
    ON CONFLICT (event_id, user_id)
    DO UPDATE SET status = ${status}
    RETURNING *
  `;
  return result[0];
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
  revenuecat_id: string | null;
  started_at: Date | null;
  expires_at: Date | null;
  created_at: Date;
  updated_at: Date;
}

export async function syncSubscription(userId: number, params: {
  planType?: string;
  status?: string;
  revenuecatId?: string;
  startsAt?: string;
  expiresAt?: string;
}) {
  const result = await sql`
    INSERT INTO subscriptions (user_id, plan_type, status, revenuecat_id, started_at, expires_at)
    VALUES (
      ${userId},
      ${params.planType ?? null},
      ${params.status ?? 'active'},
      ${params.revenuecatId ?? null},
      ${params.startsAt ?? null},
      ${params.expiresAt ?? null}
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
      plan_type = COALESCE(${params.planType ?? null}, subscriptions.plan_type),
      status = COALESCE(${params.status ?? null}, subscriptions.status),
      revenuecat_id = COALESCE(${params.revenuecatId ?? null}, subscriptions.revenuecat_id),
      expires_at = COALESCE(${params.expiresAt ?? null}, subscriptions.expires_at),
      updated_at = NOW()
    RETURNING *
  `;
  return result[0] as Subscription;
}

export async function getSubscription(userId: number) {
  const result = await sql`
    SELECT * FROM subscriptions WHERE user_id = ${userId}
  `;
  return result.length ? result[0] as Subscription : null;
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
    FROM users WHERE provider != 'seed'`,
    sql`SELECT COUNT(*) as total FROM matches`,
    sql`SELECT COUNT(*) as total FROM messages`,
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

export async function createCouple(
  userId: number,
  partnerId: number,
  relationshipStatus: string = 'dating',
  startedAt?: Date
) {
  // Order user IDs to prevent duplicates
  const [user1, user2] = userId < partnerId ? [userId, partnerId] : [partnerId, userId];

  const result = await sql`
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
  `;

  return result.length ? result[0] : null;
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

  // Create new question for today
  const result = await sql`
    INSERT INTO couple_questions (couple_id, question, category, asked_at)
    VALUES (${coupleId}, ${questionData.question}, ${questionData.category}, CURRENT_DATE)
    RETURNING *
  `;

  return result[0];
}

export async function answerDailyQuestion(
  coupleId: number,
  questionId: number,
  userId: number,
  answer: string
) {
  // Determine if this is user1 or user2
  const couple = await sql`
    SELECT user1_id, user2_id FROM couples WHERE id = ${coupleId}
  `;

  if (couple.length === 0) throw new Error("Couple not found");

  const isUser1 = (couple[0] as any).user1_id === userId;
  const column = isUser1 ? 'user1_answer' : 'user2_answer';

  if (isUser1) {
    await sql`
      UPDATE couple_questions
      SET user1_answer = ${answer}
      WHERE id = ${questionId}
    `;
  } else {
    await sql`
      UPDATE couple_questions
      SET user2_answer = ${answer}
      WHERE id = ${questionId}
    `;
  }
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
    SELECT url, position FROM profile_photos
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
    photos: photos.map((p: any) => p.url),
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

// Delete user completely
export async function deleteUserCompletely(userId: number, adminEmail: string) {
  // Log before deletion
  await logModerationAction({
    adminEmail,
    action: 'delete_user',
    targetType: 'user',
    targetId: userId,
  });

  // Delete in order (respecting foreign keys)
  await sql`DELETE FROM admin_notes WHERE user_id = ${userId}`;
  await sql`DELETE FROM user_bans WHERE user_id = ${userId}`;
  await sql`DELETE FROM profile_photos WHERE user_id = ${userId}`;
  await sql`DELETE FROM swipes WHERE user_id = ${userId} OR target_user_id = ${userId}`;
  await sql`DELETE FROM event_rsvps WHERE user_id = ${userId}`;
  await sql`DELETE FROM subscriptions WHERE user_id = ${userId}`;
  await sql`DELETE FROM profiles WHERE user_id = ${userId}`;
  await sql`DELETE FROM users WHERE id = ${userId}`;

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

// Add profile photo
export async function addProfilePhoto(params: {
  userId: number;
  url: string;
  position?: number;
  isPrimary?: boolean;
}) {
  // If this is the first photo or marked as primary, set it as primary
  const existingPhotos = await getProfilePhotos(params.userId);
  const shouldBePrimary = params.isPrimary || existingPhotos.length === 0;
  const position = params.position ?? existingPhotos.length;

  // If setting as primary, unset other primaries
  if (shouldBePrimary) {
    await sql`
      UPDATE profile_photos SET is_primary = false WHERE user_id = ${params.userId}
    `;
  }

  const result = await sql`
    INSERT INTO profile_photos (user_id, url, position, is_primary)
    VALUES (${params.userId}, ${params.url}, ${position}, ${shouldBePrimary})
    RETURNING *
  `;
  return result[0];
}

// Delete profile photo
export async function deleteProfilePhoto(photoId: number, userId: number) {
  // Get the photo to check if it's primary
  const photo = await sql`
    SELECT * FROM profile_photos WHERE id = ${photoId} AND user_id = ${userId}
  `;

  if (photo.length === 0) {
    throw new Error("Photo not found");
  }

  await sql`DELETE FROM profile_photos WHERE id = ${photoId} AND user_id = ${userId}`;

  // If deleted photo was primary, set the first remaining as primary
  if (photo[0].is_primary) {
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
    await sql`UPDATE profile_photos SET position = ${i} WHERE id = ${remaining[i].id}`;
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
      throw new Error("Invalid photo ID");
    }
  }

  // Update positions
  for (let i = 0; i < photoIds.length; i++) {
    await sql`
      UPDATE profile_photos
      SET position = ${i}, is_primary = ${i === 0}
      WHERE id = ${photoIds[i]} AND user_id = ${userId}
    `;
  }

  return await getProfilePhotos(userId);
}

// Set profile photo as primary
export async function setProfilePhotoPrimary(photoId: number, userId: number) {
  // Unset all primaries for this user
  await sql`UPDATE profile_photos SET is_primary = false WHERE user_id = ${userId}`;

  // Set this one as primary
  await sql`UPDATE profile_photos SET is_primary = true WHERE id = ${photoId} AND user_id = ${userId}`;

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

// Update campaign
export async function updateCampaign(campaignId: number, params: Partial<{
  title: string;
  subject: string;
  content: string;
  segmentId: number;
  scheduledAt: Date;
  status: string;
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
    WHERE id = ${campaignId}
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
export async function getCampaignRecipients(segmentId?: number) {
  if (!segmentId) {
    // All active users
    return await sql`
      SELECT u.id, u.email, u.name, p.display_name
      FROM users u
      LEFT JOIN profiles p ON p.user_id = u.id
      WHERE u.is_active = true
        AND u.provider != 'seed'
        AND u.email NOT IN (SELECT email FROM email_unsubscribes)
      ORDER BY u.created_at DESC
    `;
  }

  // Get segment filters
  const segment = await sql`SELECT * FROM user_segments WHERE id = ${segmentId}`;
  if (segment.length === 0) return [];

  const filters = (segment[0] as any).filters;

  // Build dynamic query based on filters
  // For now, return all users - filters can be applied in JS
  return await sql`
    SELECT u.id, u.email, u.name, p.display_name, p.location, p.gender,
           DATE_PART('year', AGE(p.birthdate)) as age
    FROM users u
    LEFT JOIN profiles p ON p.user_id = u.id
    WHERE u.is_active = true
      AND u.provider != 'seed'
      AND u.email NOT IN (SELECT email FROM email_unsubscribes)
    ORDER BY u.created_at DESC
  `;
}

// Send campaign (mark as sent and create recipients)
export async function sendCampaign(campaignId: number) {
  const campaign = await getCampaignById(campaignId);
  if (!campaign) throw new Error('Campaign not found');

  const recipients = await getCampaignRecipients((campaign as any).segment_id);

  // Create recipient records
  for (const r of recipients as any[]) {
    await sql`
      INSERT INTO campaign_recipients (campaign_id, user_id, email, sent_at)
      VALUES (${campaignId}, ${r.id}, ${r.email}, NOW())
      ON CONFLICT DO NOTHING
    `;
  }

  // Update campaign status
  await sql`
    UPDATE campaigns
    SET status = 'sent', sent_at = NOW(), stats_sent = ${recipients.length}
    WHERE id = ${campaignId}
  `;

  return { sent: recipients.length, recipients };
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

// Get reports
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
        p.display_name as reported_display_name
      FROM reports r
      LEFT JOIN users reporter ON reporter.id = r.reporter_id
      LEFT JOIN users reported ON reported.id = r.reported_user_id
      LEFT JOIN profiles p ON p.user_id = r.reported_user_id
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
      p.display_name as reported_display_name
    FROM reports r
    LEFT JOIN users reporter ON reporter.id = r.reporter_id
    LEFT JOIN users reported ON reported.id = r.reported_user_id
    LEFT JOIN profiles p ON p.user_id = r.reported_user_id
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
    SELECT * FROM couple_activities WHERE id = ${activityId}
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

// Create booking
export async function createCoupleBooking(params: {
  coupleId: number;
  activityId?: number;
  eventId?: number;
  bookingDate: string;
  bookingTime?: string;
  notes?: string;
}) {
  return await sql`
    INSERT INTO couple_bookings (couple_id, activity_id, event_id, booking_date, booking_time, notes, status)
    VALUES (${params.coupleId}, ${params.activityId ?? null}, ${params.eventId ?? null}, ${params.bookingDate}, ${params.bookingTime ?? null}, ${params.notes ?? null}, 'confirmed')
    RETURNING *
  `;
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
    SELECT * FROM couple_events WHERE id = ${eventId}
  `;
  return result.length ? result[0] : null;
}

// Register for couple event
export async function registerForCoupleEvent(coupleId: number, eventId: number) {
  // Check availability
  const event = await getCoupleEvent(eventId);
  if (!event) throw new Error("Event not found");
  if ((event as any).max_couples && (event as any).current_couples >= (event as any).max_couples) {
    throw new Error("Event is full");
  }

  // Register
  const registration = await sql`
    INSERT INTO couple_event_registrations (couple_id, event_id)
    VALUES (${coupleId}, ${eventId})
    ON CONFLICT (couple_id, event_id) DO UPDATE SET status = 'registered', cancelled_at = NULL
    RETURNING *
  `;

  // Update count
  await sql`
    UPDATE couple_events SET current_couples = current_couples + 1 WHERE id = ${eventId}
  `;

  return registration[0];
}

// Cancel registration
export async function cancelCoupleEventRegistration(coupleId: number, eventId: number) {
  const result = await sql`
    UPDATE couple_event_registrations
    SET status = 'cancelled', cancelled_at = NOW()
    WHERE couple_id = ${coupleId} AND event_id = ${eventId}
    RETURNING *
  `;

  if (result.length > 0) {
    await sql`
      UPDATE couple_events SET current_couples = GREATEST(0, current_couples - 1) WHERE id = ${eventId}
    `;
  }

  return result[0];
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

  const activities = [
    // Bien-être
    { title: "Spa Cinq Mondes - Duo", description: "Massage relaxant en duo dans un cadre zen inspiré des rituels du monde. Hammam, sauna et espace détente inclus.", category: "wellness", subcategory: "spa", image_url: "https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=800", price_cents: 18000, location: "Spa Cinq Mondes", address: "6 Square de l'Opéra Louis Jouvet, 75009 Paris", city: "Paris", rating: 4.8, review_count: 324, duration_minutes: 90, is_partner: true, discount_percent: 15, tags: ["massage", "duo", "détente", "hammam"] },
    { title: "Massage aux Pierres Chaudes", description: "Un moment de pure relaxation à deux avec un massage aux pierres volcaniques chaudes.", category: "wellness", subcategory: "massage", image_url: "https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?w=800", price_cents: 15000, location: "Spa Nuxe", address: "32 Rue Montorgueil, 75001 Paris", city: "Paris", rating: 4.7, review_count: 189, duration_minutes: 60, tags: ["massage", "pierres chaudes", "relaxation"] },
    { title: "Yoga en Duo", description: "Séance de yoga spécialement conçue pour les couples. Renforcez votre connexion à travers des postures synchronisées.", category: "wellness", subcategory: "yoga", image_url: "https://images.unsplash.com/photo-1599901860904-17e6ed7083a0?w=800", price_cents: 6000, location: "Yoga Village", address: "13 Rue de la Paix, 75002 Paris", city: "Paris", rating: 4.9, review_count: 156, duration_minutes: 75, tags: ["yoga", "duo", "méditation", "bien-être"] },
    { title: "Bains Nordiques", description: "Expérience thermale inspirée des traditions scandinaves. Alternez entre bains chauds, froids et repos.", category: "wellness", subcategory: "bains", image_url: "https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800", price_cents: 8500, location: "Les Bains du Marais", address: "31 Rue des Blancs Manteaux, 75004 Paris", city: "Paris", rating: 4.6, review_count: 278, duration_minutes: 120, tags: ["bains", "nordique", "sauna", "détente"] },

    // Gastronomie
    { title: "Cours de Cuisine en Amoureux", description: "Apprenez à préparer un menu gastronomique à 4 mains avec un chef étoilé.", category: "gastronomy", subcategory: "cooking", image_url: "https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800", price_cents: 14000, location: "L'atelier des Chefs", address: "10 Rue de Penthièvre, 75008 Paris", city: "Paris", rating: 4.8, review_count: 412, duration_minutes: 180, is_partner: true, discount_percent: 10, tags: ["cuisine", "chef", "gastronomie", "cours"] },
    { title: "Dégustation de Vins Casher", description: "Découvrez les meilleurs vins casher d'Israël et de France lors d'une dégustation guidée par un sommelier.", category: "gastronomy", subcategory: "wine", image_url: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800", price_cents: 7500, location: "Cave Casher", address: "42 Rue Richer, 75009 Paris", city: "Paris", rating: 4.7, review_count: 98, duration_minutes: 90, is_kosher: true, tags: ["vin", "casher", "dégustation", "sommelier"] },
    { title: "Dîner aux Chandelles", description: "Restaurant gastronomique avec vue sur la Tour Eiffel. Menu dégustation 7 services.", category: "gastronomy", subcategory: "restaurant", image_url: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800", price_cents: 25000, location: "Le Jules Verne", address: "Tour Eiffel, 75007 Paris", city: "Paris", rating: 4.9, review_count: 567, duration_minutes: 150, tags: ["gastronomie", "romantique", "vue", "étoilé"] },
    { title: "Pâtisserie Française", description: "Cours de pâtisserie pour apprendre les classiques français : macarons, éclairs, tarte au citron.", category: "gastronomy", subcategory: "pastry", image_url: "https://images.unsplash.com/photo-1612203985729-70726954388c?w=800", price_cents: 9500, location: "École Ducasse", address: "64 Rue du Ranelagh, 75016 Paris", city: "Paris", rating: 4.8, review_count: 234, duration_minutes: 180, tags: ["pâtisserie", "macarons", "cours", "sucré"] },

    // Culture
    { title: "Visite Privée du Louvre", description: "Découvrez les chefs-d'œuvre du Louvre avec un guide privé, hors des heures d'affluence.", category: "culture", subcategory: "museum", image_url: "https://images.unsplash.com/photo-1499426600726-ac541d8a0aee?w=800", price_cents: 22000, location: "Musée du Louvre", address: "Rue de Rivoli, 75001 Paris", city: "Paris", rating: 4.9, review_count: 189, duration_minutes: 150, tags: ["musée", "art", "visite privée", "culture"] },
    { title: "Opéra Garnier - Soirée Ballet", description: "Assistez à un ballet classique dans le cadre somptueux de l'Opéra Garnier.", category: "culture", subcategory: "show", image_url: "https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?w=800", price_cents: 18000, location: "Opéra Garnier", address: "Place de l'Opéra, 75009 Paris", city: "Paris", rating: 4.9, review_count: 445, duration_minutes: 180, tags: ["opéra", "ballet", "danse", "classique"] },
    { title: "Concert Jazz Intime", description: "Soirée jazz dans un club mythique parisien. Cocktails et musique live.", category: "culture", subcategory: "concert", image_url: "https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=800", price_cents: 6500, location: "Duc des Lombards", address: "42 Rue des Lombards, 75001 Paris", city: "Paris", rating: 4.7, review_count: 312, duration_minutes: 120, tags: ["jazz", "musique live", "cocktails", "intime"] },
    { title: "Escape Game Romantique", description: "Escape game spécialement conçu pour les couples. Résolvez les énigmes ensemble!", category: "culture", subcategory: "game", image_url: "https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=800", price_cents: 5000, location: "Lock Academy", address: "26 Rue Coquillière, 75001 Paris", city: "Paris", rating: 4.6, review_count: 567, duration_minutes: 60, tags: ["escape game", "énigmes", "fun", "duo"] },

    // Sport & Aventure
    { title: "Cours de Danse Latine", description: "Apprenez la salsa, bachata ou kizomba à deux. Tous niveaux acceptés.", category: "sport", subcategory: "dance", image_url: "https://images.unsplash.com/photo-1504609813442-a8924e83f76e?w=800", price_cents: 4500, location: "Studio Bleu", address: "10 Rue de la Gaîté, 75014 Paris", city: "Paris", rating: 4.8, review_count: 234, duration_minutes: 90, tags: ["danse", "salsa", "bachata", "latino"] },
    { title: "Balade à Cheval en Forêt", description: "Promenade romantique à cheval à travers la forêt de Fontainebleau.", category: "sport", subcategory: "horse", image_url: "https://images.unsplash.com/photo-1553284965-83fd3e82fa5a?w=800", price_cents: 12000, location: "Centre Équestre", address: "Route de la Reine, 77300 Fontainebleau", city: "Fontainebleau", rating: 4.7, review_count: 89, duration_minutes: 120, tags: ["cheval", "nature", "balade", "forêt"] },
    { title: "Vol en Montgolfière", description: "Survolez les châteaux de la Loire au lever du soleil. Champagne inclus!", category: "sport", subcategory: "flying", image_url: "https://images.unsplash.com/photo-1507608616759-54f48f0af0ee?w=800", price_cents: 35000, location: "France Montgolfières", address: "Loire Valley", city: "Tours", rating: 4.9, review_count: 156, duration_minutes: 180, tags: ["montgolfière", "vol", "champagne", "châteaux"] },
    { title: "Kayak au Coucher du Soleil", description: "Balade en kayak biplace sur la Seine au coucher du soleil.", category: "sport", subcategory: "kayak", image_url: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800", price_cents: 5500, location: "Kayak Paris", address: "Port de Javel, 75015 Paris", city: "Paris", rating: 4.6, review_count: 178, duration_minutes: 90, tags: ["kayak", "seine", "coucher de soleil", "eau"] },

    // Romantique
    { title: "Croisière Champagne sur la Seine", description: "Croisière privative avec champagne et petit fours, vue sur Paris illuminé.", category: "romantic", subcategory: "cruise", image_url: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800", price_cents: 16000, location: "Bateaux Parisiens", address: "Port de la Bourdonnais, 75007 Paris", city: "Paris", rating: 4.8, review_count: 345, duration_minutes: 90, is_partner: true, discount_percent: 20, tags: ["croisière", "champagne", "seine", "romantique"] },
    { title: "Pique-nique Gastronomique", description: "Panier gourmet livré au parc de votre choix. Produits frais et vin inclus.", category: "romantic", subcategory: "picnic", image_url: "https://images.unsplash.com/photo-1526662092594-e98c1e356d6a?w=800", price_cents: 8500, location: "Jardin du Luxembourg", address: "Jardin du Luxembourg, 75006 Paris", city: "Paris", rating: 4.7, review_count: 123, duration_minutes: 120, tags: ["pique-nique", "gourmet", "parc", "romantique"] },
    { title: "Séance Photo Couple", description: "Shooting photo professionnel dans les plus beaux quartiers de Paris.", category: "romantic", subcategory: "photo", image_url: "https://images.unsplash.com/photo-1529634597503-139d3726fed5?w=800", price_cents: 25000, location: "Paris", address: "Montmartre, 75018 Paris", city: "Paris", rating: 4.9, review_count: 267, duration_minutes: 120, tags: ["photo", "shooting", "souvenir", "professionnel"] },
    { title: "Soirée Cabaret au Moulin Rouge", description: "Le célèbre show du Moulin Rouge avec dîner et champagne.", category: "romantic", subcategory: "show", image_url: "https://images.unsplash.com/photo-1550411294-875f8f4c9d4f?w=800", price_cents: 35000, location: "Moulin Rouge", address: "82 Boulevard de Clichy, 75018 Paris", city: "Paris", rating: 4.8, review_count: 789, duration_minutes: 240, tags: ["cabaret", "show", "champagne", "dîner"] },

    // Voyage
    { title: "Week-end à Deauville", description: "2 jours/1 nuit dans un hôtel de charme avec spa. Petit-déjeuner inclus.", category: "travel", subcategory: "weekend", image_url: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800", price_cents: 45000, location: "Hôtel Normandy Barrière", address: "38 Rue Jean Mermoz, 14800 Deauville", city: "Deauville", rating: 4.7, review_count: 234, duration_minutes: 2880, tags: ["week-end", "plage", "spa", "normandie"] },
    { title: "Escapade Romantique à Bruges", description: "2 jours dans la Venise du Nord. Balades, chocolat et bière belge.", category: "travel", subcategory: "city", image_url: "https://images.unsplash.com/photo-1491557345352-5929e343eb89?w=800", price_cents: 38000, location: "Bruges", address: "Bruges, Belgique", city: "Bruges", rating: 4.8, review_count: 156, duration_minutes: 2880, tags: ["bruges", "belgique", "romantique", "chocolat"] },
    { title: "Shabbaton à la Montagne", description: "Week-end shabbat dans un chalet à la montagne. Repas casher et ambiance chaleureuse.", category: "travel", subcategory: "spiritual", image_url: "https://images.unsplash.com/photo-1520984032042-162d526883e0?w=800", price_cents: 55000, location: "Chalet Alpin", address: "Megève, 74120", city: "Megève", rating: 4.9, review_count: 67, duration_minutes: 4320, is_kosher: true, tags: ["shabbat", "montagne", "casher", "spirituel"] },

    // Spirituel
    { title: "Cours de Torah en Couple", description: "Étude de textes sur le couple dans la tradition juive avec un rabbin.", category: "spiritual", subcategory: "study", image_url: "https://images.unsplash.com/photo-1457369804613-52c61a468e7d?w=800", price_cents: 0, location: "Centre Communautaire", address: "17 Rue des Rosiers, 75004 Paris", city: "Paris", rating: 4.9, review_count: 45, duration_minutes: 90, is_kosher: true, tags: ["torah", "étude", "couple", "spiritualité"] },
    { title: "Préparation Shabbat", description: "Atelier de préparation du Shabbat en couple : challah, kiddoush, bénédictions.", category: "spiritual", subcategory: "cooking", image_url: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800", price_cents: 4500, location: "Beth Loubavitch", address: "8 Rue Lamartine, 75009 Paris", city: "Paris", rating: 4.8, review_count: 78, duration_minutes: 120, is_kosher: true, tags: ["shabbat", "challah", "préparation", "tradition"] },

    // DIY
    { title: "Atelier Poterie en Duo", description: "Créez vos propres pièces en céramique. Tournage, modelage et émaillage.", category: "diy", subcategory: "pottery", image_url: "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=800", price_cents: 8500, location: "L'Atelier Céramique", address: "23 Rue de la Folie Méricourt, 75011 Paris", city: "Paris", rating: 4.7, review_count: 189, duration_minutes: 180, tags: ["poterie", "céramique", "création", "artisanat"] },
    { title: "Peinture sur Toile", description: "Soirée peinture avec un verre de vin. Guidé par un artiste, repartez avec votre création.", category: "diy", subcategory: "painting", image_url: "https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=800", price_cents: 6500, location: "Art & Vin", address: "15 Rue du Faubourg Saint-Antoine, 75011 Paris", city: "Paris", rating: 4.6, review_count: 234, duration_minutes: 150, tags: ["peinture", "art", "vin", "création"] },
    { title: "Fabrication de Bougies", description: "Créez vos propres bougies parfumées. Parfait pour les bougies de Shabbat!", category: "diy", subcategory: "candles", image_url: "https://images.unsplash.com/photo-1602607015644-e2b8b213a0f8?w=800", price_cents: 5500, location: "La Maison des Bougies", address: "45 Rue de Turenne, 75003 Paris", city: "Paris", rating: 4.7, review_count: 156, duration_minutes: 120, is_kosher: true, tags: ["bougies", "DIY", "shabbat", "parfum"] }
  ];

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

  const events = [
    { title: "Shabbat Dinner Couples", description: "Soirée Shabbat exclusive pour couples. Dîner casher gastronomique, chants et ambiance chaleureuse.", category: "dinner", image_url: "https://images.unsplash.com/photo-1529543544277-c91e2e51c71a?w=800", event_date: "2026-01-24", event_time: "19:00", end_time: "23:00", location: "Le Marais", address: "24 Rue des Écouffes, 75004 Paris", city: "Paris", price_cents: 12000, max_couples: 15, is_kosher: true, dress_code: "Élégant décontracté", what_included: "Dîner 4 services, vin, dessert", is_featured: true },
    { title: "Wine & Cheese Couples", description: "Dégustation de vins casher et fromages dans une cave historique du Marais.", category: "tasting", image_url: "https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800", event_date: "2026-01-31", event_time: "20:00", end_time: "22:30", location: "Cave du Marais", address: "42 Rue de Bretagne, 75003 Paris", city: "Paris", price_cents: 8500, max_couples: 12, is_kosher: true, what_included: "5 vins, plateau de fromages, pain", is_featured: true },
    { title: "Soirée Dansante Années 80", description: "Retrouvez les tubes des années 80! DJ, buffet et open bar.", category: "party", image_url: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800", event_date: "2026-02-08", event_time: "21:00", end_time: "02:00", location: "Salle des Fêtes", address: "156 Rue de Rivoli, 75001 Paris", city: "Paris", price_cents: 9000, max_couples: 50, dress_code: "Tenue années 80", what_included: "Buffet, open bar soft, DJ" },
    { title: "Week-end Couples à Deauville", description: "Escapade de 2 jours en Normandie. Hôtel 4*, spa, repas et activités.", category: "travel", image_url: "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800", event_date: "2026-02-14", event_time: "10:00", end_time: "18:00", location: "Deauville", address: "Hôtel Royal Barrière, Deauville", city: "Deauville", price_cents: 65000, max_couples: 10, dress_code: "Décontracté chic", what_included: "2 nuits, petits-déjeuners, 1 dîner, accès spa", is_featured: true },
    { title: "Cours de Salsa Couples", description: "Apprenez la salsa cubaine en groupe de couples. Tous niveaux!", category: "workshop", image_url: "https://images.unsplash.com/photo-1545128485-c400e7702796?w=800", event_date: "2026-02-01", event_time: "19:30", end_time: "21:30", location: "Studio Latino", address: "78 Rue de la Roquette, 75011 Paris", city: "Paris", price_cents: 4000, max_couples: 15, what_included: "2h de cours, rafraîchissements" },
    { title: "Brunch Couples du Dimanche", description: "Brunch gastronomique pour couples dans un lieu d'exception.", category: "brunch", image_url: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800", event_date: "2026-01-26", event_time: "11:00", end_time: "14:00", location: "Hôtel Plaza Athénée", address: "25 Avenue Montaigne, 75008 Paris", city: "Paris", price_cents: 15000, max_couples: 20, dress_code: "Smart casual", what_included: "Buffet à volonté, champagne, jus frais" },
    { title: "Retraite Spirituelle Couples", description: "Week-end de ressourcement spirituel. Étude, méditation et repas casher.", category: "spiritual", image_url: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800", event_date: "2026-03-07", event_time: "09:00", end_time: "18:00", location: "Centre Beth Yossef", address: "Fontainebleau", city: "Fontainebleau", price_cents: 35000, max_couples: 8, is_kosher: true, what_included: "Hébergement, repas casher, cours", is_featured: true },
    { title: "Atelier Cocktails en Couple", description: "Apprenez à créer des cocktails avec un mixologue professionnel.", category: "workshop", image_url: "https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800", event_date: "2026-02-15", event_time: "18:00", end_time: "20:30", location: "Bar Le Syndicat", address: "51 Rue du Faubourg Saint-Denis, 75010 Paris", city: "Paris", price_cents: 7500, max_couples: 10, what_included: "3 cocktails par personne, recettes" },
    { title: "Escape Game Team Couples", description: "Compétition d'escape game entre couples! Qui résoudra les énigmes le plus vite?", category: "game", image_url: "https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=800", event_date: "2026-02-22", event_time: "14:00", end_time: "17:00", location: "Lock Academy", address: "26 Rue Coquillière, 75001 Paris", city: "Paris", price_cents: 5000, max_couples: 8, what_included: "2 parties, goûter, prix pour les gagnants" },
    { title: "Concert Privé Jazz", description: "Concert de jazz intimiste réservé aux couples MAZL.", category: "concert", image_url: "https://images.unsplash.com/photo-1511192336575-5a79af67a629?w=800", event_date: "2026-02-28", event_time: "20:30", end_time: "23:00", location: "Sunset Jazz Club", address: "60 Rue des Lombards, 75001 Paris", city: "Paris", price_cents: 6500, max_couples: 25, what_included: "Concert, 1 cocktail par personne" }
  ];

  for (const event of events) {
    await sql`
      INSERT INTO couple_events (title, description, category, image_url, event_date, event_time, end_time, location, address, city, price_cents, max_couples, is_kosher, dress_code, what_included, is_featured)
      VALUES (${event.title}, ${event.description}, ${event.category}, ${event.image_url}, ${event.event_date}, ${event.event_time}, ${event.end_time ?? null}, ${event.location}, ${event.address ?? null}, ${event.city}, ${event.price_cents}, ${event.max_couples}, ${event.is_kosher ?? false}, ${event.dress_code ?? null}, ${event.what_included ?? null}, ${event.is_featured ?? false})
    `;
  }

  console.log(`Seeded ${events.length} couple events`);
}
