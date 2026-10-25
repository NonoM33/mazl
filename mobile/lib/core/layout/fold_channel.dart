import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fold_state.dart';

/// The fold states of the device, streamed by the iOS side
/// (`ios/Runner/FoldPosturePlugin.swift`, iOS 27.1 hinge and reserved-region
/// APIs). Flutter does not report the fold of an iPhone by itself
/// (`MediaQuery.displayFeatures` is Android only).
///
/// Off iOS, on an older system or without the native side (tests), the
/// stream stays on [FoldState.unknown]: the layout is then the flat one.
Stream<FoldState> platformFoldStates({
  EventChannel channel = const EventChannel('mazl/fold'),
  TargetPlatform? platform,
}) {
  if ((platform ?? defaultTargetPlatform) != TargetPlatform.iOS || kIsWeb) {
    return Stream<FoldState>.value(FoldState.unknown);
  }
  return channel
      .receiveBroadcastStream()
      .map(FoldState.fromMessage)
      .handleError(
        (Object error) {
          debugPrint('mazl/fold: $error');
        },
        test: (error) =>
            error is PlatformException || error is MissingPluginException,
      );
}
