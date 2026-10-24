import 'package:flutter/widgets.dart';

import '../../presentation/features/chat/screens/chat_screen.dart';
import '../../presentation/features/profile/screens/profile_view_screen.dart';
import '../layout/adaptive_detail.dart';

/// The screen of a detail: the same widget fills the window on a compact
/// width (the route's page) and the detail pane on a regular one.
Widget detailScreenFor(BuildContext context, DetailTarget target) => switch (target) {
  ChatDetail(:final conversationId) => ChatScreen(conversationId: conversationId),
  MatchProfileDetail(:final userId) => ProfileViewScreen(userId: userId, isFromMatch: true),
};
