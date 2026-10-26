import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers/analytics_providers.dart';
import 'analytics_event.dart';

/// Records [event] from a screen that is not a Riverpod widget. Without a
/// [ProviderScope] above [context] (a bare widget test) nothing is recorded.
/// A `null` event (refused by the formats of the plan) is ignored.
void trackEvent(BuildContext context, AnalyticsEvent? event) {
  if (event == null) return;
  final scope = context
      .getInheritedWidgetOfExactType<UncontrolledProviderScope>();
  scope?.container.read(analyticsProvider).track(event);
}
