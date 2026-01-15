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
      await sql`
        INSERT INTO matches (user1_id, user2_id)
        VALUES (${user1}, ${user2})
        ON CONFLICT (user1_id, user2_id) DO NOTHING
      `;
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
