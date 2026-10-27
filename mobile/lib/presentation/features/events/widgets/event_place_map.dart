import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/l10n.dart';

/// The place of an event on a map, and a button that opens it in Apple Plans.
///
/// The map shows the NEIGHBOURHOOD, a circle of [areaRadiusMeters] around the
/// coordinates, not a pin: the address of an event stays hidden until its
/// registrations open. With [preciseAddress] (the event is open and gives its
/// address) the pin is exact.
///
/// On iOS it is a real Apple Plans map (MapKit, `ios/Runner/
/// EventMapPlugin.swift`, no API key), dark in dark mode. It does not capture
/// the page's scroll: it is first a picture the page scrolls past; a touch
/// makes it explorable (move, zoom) until « Terminé ». Elsewhere (Android,
/// tests) a static sketch of the same circle stands in.
class EventPlaceMap extends StatelessWidget {
  const EventPlaceMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.placeName,
    required this.preciseAddress,
    this.height = 200,
  });

  final double latitude;
  final double longitude;
  final String? placeName;
  final bool preciseAddress;
  final double height;

  static const areaRadiusMeters = 600.0;
  static const cornerRadius = 20.0;

  /// How a test follows the « Ouvrir dans Plans » button.
  @visibleForTesting
  static Future<bool> Function(Uri uri) launcher = (uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  static bool get _hasNativeMap =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  /// The link that opens Apple Plans on the place.
  Uri get plansUri => Uri.https('maps.apple.com', '/', {
    'll': '$latitude,$longitude',
    'z': '15',
    if (preciseAddress && placeName != null) 'q': placeName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final map = SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _hasNativeMap
              ? _NativeMap(
                  latitude: latitude,
                  longitude: longitude,
                  preciseAddress: preciseAddress,
                )
              : _SketchMap(preciseAddress: preciseAddress),
          if (!preciseAddress)
            PositionedDirectional(
              top: 12,
              start: 12,
              child: _MapChip(
                icon: LucideIcons.circleDashed,
                label: l10n.eventsMapArea,
              ),
            ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l10n.eventsMapSemantics,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius),
            child: map,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => launcher(plansUri),
          icon: const Icon(LucideIcons.navigation, size: 18),
          label: Text(l10n.eventsMapOpenInMaps),
        ),
      ],
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chip = Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurface),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    // A 44 pt target around a smaller chip.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Center(child: chip),
      ),
    );
  }
}

/// A static sketch of the neighbourhood: faint streets, the circle, and the
/// pin when the address is public.
class _SketchMap extends StatelessWidget {
  const _SketchMap({required this.preciseAddress});

  final bool preciseAddress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _SketchPainter(
        background: scheme.surfaceContainerHighest,
        streets: scheme.onSurface.withValues(alpha: 0.10),
        accent: scheme.primary,
      ),
      child: preciseAddress
          ? Center(
              child: Icon(LucideIcons.mapPin, size: 32, color: scheme.primary),
            )
          : null,
    );
  }
}

class _SketchPainter extends CustomPainter {
  _SketchPainter({
    required this.background,
    required this.streets,
    required this.accent,
  });

  final Color background;
  final Color streets;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final street = Paint()
      ..color = streets
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    for (final fraction in [0.18, 0.47, 0.8]) {
      canvas.drawLine(
        Offset(0, size.height * fraction),
        Offset(size.width, size.height * (fraction + 0.12)),
        street,
      );
    }
    for (final fraction in [0.12, 0.4, 0.7, 0.93]) {
      canvas.drawLine(
        Offset(size.width * fraction, 0),
        Offset(size.width * (fraction - 0.1), size.height),
        street,
      );
    }
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.32;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = accent.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = accent.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SketchPainter old) =>
      old.background != background ||
      old.streets != streets ||
      old.accent != accent;
}

/// The Apple Plans map (a UIKit view). Locked while the page scrolls: a touch
/// unlocks it.
class _NativeMap extends StatefulWidget {
  const _NativeMap({
    required this.latitude,
    required this.longitude,
    required this.preciseAddress,
  });

  final double latitude;
  final double longitude;
  final bool preciseAddress;

  @override
  State<_NativeMap> createState() => _NativeMapState();
}

class _NativeMapState extends State<_NativeMap> {
  MethodChannel? _channel;
  bool _interactive = false;
  bool? _dark;

  void _setInteractive(bool value) {
    setState(() => _interactive = value);
    _channel?.invokeMethod<void>('setInteractive', {'value': value});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_dark != null && _dark != dark) {
      _channel?.invokeMethod<void>('setDark', {'value': dark});
    }
    _dark = dark;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        UiKitView(
          viewType: 'mazl/event_map',
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: <String, Object?>{
            'latitude': widget.latitude,
            'longitude': widget.longitude,
            'radius': EventPlaceMap.areaRadiusMeters,
            'pin': widget.preciseAddress,
            'dark': dark,
            'tint': Theme.of(context).colorScheme.primary.toARGB32(),
            'cornerRadius': EventPlaceMap.cornerRadius,
          },
          // Locked: no gesture goes to the map, the page scrolls over it.
          // Unlocked: the map takes every gesture.
          gestureRecognizers: _interactive
              ? <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    EagerGestureRecognizer.new,
                  ),
                }
              : const <Factory<OneSequenceGestureRecognizer>>{},
          onPlatformViewCreated: (id) {
            _channel = MethodChannel('mazl/event_map_$id');
            _channel?.invokeMethod<void>('setInteractive', {
              'value': _interactive,
            });
          },
        ),
        if (!_interactive)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _setInteractive(true),
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _MapChip(
                    icon: LucideIcons.move,
                    label: l10n.eventsMapExplore,
                  ),
                ),
              ),
            ),
          )
        else
          PositionedDirectional(
            top: 4,
            end: 4,
            child: _MapChip(
              icon: LucideIcons.check,
              label: l10n.eventsMapDone,
              onTap: () => _setInteractive(false),
            ),
          ),
      ],
    );
  }
}
