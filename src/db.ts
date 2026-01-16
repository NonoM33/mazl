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

  console.log("Database initialized");

  // Seed fake profiles if empty
  await seedFakeProfiles();
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
      CASE
        WHEN m.user1_id = ${userId} THEN m.user2_id
        ELSE m.user1_id
      END as other_user_id
    FROM matches m
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
    profile: profileMap.get(m.other_user_id),
  }));
}

// ============ SEED FAKE PROFILES ============

async function seedFakeProfiles() {
  // Check if we already have fake profiles
  const existingCount = await sql`SELECT COUNT(*) as count FROM users WHERE provider = 'seed'`;
  if (parseInt((existingCount[0] as any).count) > 0) {
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
    `;

    // Add profile photo
    await sql`
      INSERT INTO profile_photos (user_id, url, position, is_primary)
      VALUES (${userId}, ${`https://i.pravatar.cc/400?img=${i + 1}`}, 0, true)
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
    `;

    // Add profile photo
    await sql`
      INSERT INTO profile_photos (user_id, url, position, is_primary)
      VALUES (${userId}, ${`https://i.pravatar.cc/400?img=${i + 50}`}, 0, true)
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
  return messages.reverse(); // Return in chronological order
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
