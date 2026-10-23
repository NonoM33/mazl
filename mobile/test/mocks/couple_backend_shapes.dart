// JSON as `couple.content.routes.ts` sends it, written from the table
// definitions and the SELECTs of `src/db.ts` (not from the Dart parsers):
//  - `SELECT *` rows carry every column, including the ones the app ignores;
//  - DECIMAL columns (rating, latitude, longitude) are strings;
//  - COUNT(*) is a bigint and arrives as a string;
//  - DATE / TIMESTAMP columns are ISO strings;
//  - errors are `{ success: false, error: "<english text>" }`.

Map<String, dynamic> activityRow({
  int id = 1,
  String title = 'Spa en duo',
  String category = 'wellness',
  String? city = 'Paris',
}) => {
  'id': id,
  'title': title,
  'description': 'Moment de détente à deux.',
  'category': category,
  'subcategory': null,
  'image_url': null,
  'images': [],
  'price_cents': 12000,
  'price_type': 'fixed',
  'location': 'Spa Marais',
  'address': '1 rue des Rosiers',
  'latitude': '48.85660000',
  'longitude': '2.35220000',
  'city': city,
  'rating': '4.8',
  'review_count': 124,
  'is_kosher': true,
  'is_partner': false,
  'partner_name': null,
  'discount_percent': null,
  'discount_code': null,
  'booking_url': null,
  'phone': null,
  'website': null,
  'duration_minutes': 120,
  'available_days': ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
  'tags': ['spa', 'duo'],
  'is_active': true,
  'created_at': '2026-10-01T09:00:00.000Z',
  'updated_at': '2026-10-01T09:00:00.000Z',
};

/// A row of `getSavedActivities`: the activity plus `saved_at` and `user_notes`.
Map<String, dynamic> savedActivityRow({
  int id = 1,
  String title = 'Spa en duo',
}) => {
  ...activityRow(id: id, title: title),
  'saved_at': '2026-10-20T18:30:00.000Z',
  'user_notes': null,
};

Map<String, dynamic> eventRow({
  int id = 3,
  String title = 'Dîner de Shabbat',
  int currentCouples = 3,
  int? maxCouples = 20,
}) => {
  'id': id,
  'title': title,
  'description': 'Un dîner entre couples.',
  'category': 'dinner',
  'image_url': null,
  'images': [],
  'event_date': '2026-11-12T00:00:00.000Z',
  'event_time': '19:30:00',
  'end_time': '23:00:00',
  'location': 'Maison Cohen',
  'address': '3 rue de la Paix',
  'latitude': null,
  'longitude': null,
  'city': 'Paris',
  'price_cents': 4500,
  'max_couples': maxCouples,
  'current_couples': currentCouples,
  'is_kosher': true,
  'dress_code': 'Chic',
  'what_included': 'Dîner et boissons',
  'organizer_name': 'Famille Cohen',
  'organizer_contact': null,
  'is_published': true,
  'is_featured': false,
  'created_at': '2026-10-01T09:00:00.000Z',
  'updated_at': '2026-10-01T09:00:00.000Z',
};

/// A row of `getCoupleRegisteredEvents`.
Map<String, dynamic> registeredEventRow({int id = 3}) => {
  ...eventRow(id: id),
  'registered_at': '2026-10-21T08:00:00.000Z',
  'registration_status': 'registered',
};

Map<String, dynamic> bucketRow({
  int id = 1,
  String title = 'Voir les aurores boréales',
  bool completed = false,
}) => {
  'id': id,
  'couple_id': 12,
  'title': title,
  'description': null,
  'category': null,
  'is_completed': completed,
  'completed_at': completed ? '2026-10-22T10:00:00.000Z' : null,
  'target_date': null,
  'priority': 0,
  'created_at': '2026-10-10T10:00:00.000Z',
};

Map<String, dynamic> dateRow({
  int id = 1,
  String title = 'Notre anniversaire',
}) => {
  'id': id,
  'couple_id': 12,
  'title': title,
  'date': '2026-12-01T00:00:00.000Z',
  'type': 'anniversary',
  'is_recurring': true,
  'remind_days_before': 7,
  'notes': null,
  'created_at': '2026-10-10T10:00:00.000Z',
};

Map<String, dynamic> memoryRow({
  int id = 1,
  String title = 'Notre premier voyage',
}) => {
  'id': id,
  'couple_id': 12,
  'type': 'note',
  'title': title,
  'content': 'Rome, en avril.',
  'image_url': null,
  'memory_date': null,
  'location': null,
  'tags': [],
  'is_favorite': false,
  'created_by': 7,
  'created_at': '2026-10-10T10:00:00.000Z',
};

/// `getCoupleStats` row: every counter is a COUNT(*), hence a string.
Map<String, dynamic> statsRow({
  String saved = '3',
  String events = '1',
  String memories = '5',
}) => {
  'total_bookings': '2',
  'saved_activities': saved,
  'events_registered': events,
  'memories_count': memories,
  'bucket_completed': '1',
  'bucket_total': '4',
};

Map<String, dynamic> achievementRow() => {
  'id': 1,
  'couple_id': 12,
  'achievement_type': 'first_activity',
  'achievement_name': 'Première activité',
  'description': null,
  'icon': 'star',
  'unlocked_at': '2026-10-21T09:00:00.000Z',
};

Map<String, dynamic> ok(Map<String, dynamic> body) => {
  'success': true,
  ...body,
};

Map<String, dynamic> error(String message) => {
  'success': false,
  'error': message,
};
