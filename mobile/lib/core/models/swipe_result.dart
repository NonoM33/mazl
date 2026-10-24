/// Whether the answer of `POST /api/swipes` is a reciprocal match.
///
/// The server answers `{ success, match, targetUserId? }` (`SwipeResult` in
/// src/features/matching/swipe.routes.ts): the key is `match`, for a like, a
/// pass and a super like alike. Every screen that swipes reads it here.
bool swipeMatched(Map<String, dynamic>? body) => body?['match'] == true;
