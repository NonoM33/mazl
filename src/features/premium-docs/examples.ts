// Synthetic examples of the member API: invented first names, example.com addresses, small
// identifiers. A test refuses anything that looks real.

export const at = "2026-10-31T21:00:00.000Z";

export const passport = { city: "Tel-Aviv", latitude: 32.0853, longitude: 34.7818 };

export const settingsFree = { is_plus: false, passport: null, incognito: false, send_read_receipts: true };
export const settingsPlus = { is_plus: true, passport, incognito: true, send_read_receipts: true };

export const undone = { target_user_id: 41, action: "pass", remaining_free_undos: 0 };
export const undoneUnlimited = { target_user_id: 41, action: "like", remaining_free_undos: null };

export const bestTime = { city: "Paris", best_time: { starts_at: at, weekday: 6, hour: 21 }, scheduled_at: null };
export const bestTimeQuiet = { city: "Quietville", best_time: null, scheduled_at: null };

export const teaser = {
  display_name: "Jeanne",
  is_verified: true,
  liked_at: "2026-10-27T10:00:00.000Z",
  is_super_like: false,
  blurredPhotoUrl: "https://api.example.com/media/photos/12/blur?exp=1800000000&sig=exemple-de-signature",
};
export const fullLike = {
  user_id: 41,
  display_name: "Jeanne Exemple",
  picture: "https://api.example.com/media/photos/12?exp=1800000000&sig=exemple-de-signature",
  age: 31,
  is_verified: true,
  liked_at: "2026-10-27T10:00:00.000Z",
  is_super_like: true,
  note: "Votre sourire au Shabbat des jeunes",
};
export const receivedFree = { success: true, count: 12, is_premium: false, likes: [teaser] };
export const receivedPlus = { success: true, count: 1, is_premium: true, likes: [fullLike] };

export const discoverProfile = {
  user_id: 41,
  display_name: "Jeanne Exemple",
  age: 31,
  bio: "Bonjour, je cherche une belle histoire.",
  location: "Tel-Aviv, Israël",
  photos: ["https://api.example.com/media/photos/12?exp=1800000000&sig=exemple-de-signature"],
  super_liked_you: true,
  super_like_note: "Votre sourire au Shabbat des jeunes",
  traveling_city: "Tel-Aviv",
};

export const message = {
  id: 301,
  conversation_id: 10,
  sender_id: 7,
  client_id: "c-1",
  type: "text",
  content: "Shabbat shalom",
  created_at: "2026-10-27T20:58:00.000Z",
  read_at: "2026-10-27T21:04:00.000Z",
  is_read: true,
  unsent: false,
};

export const event = {
  id: 5,
  title: "Shabbat Exemple",
  date: "2031-01-01",
  price: "12.50",
  currency: "EUR",
  member_price_cents: 800,
  is_published: true,
};
