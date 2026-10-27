import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/images/mazl_network_image.dart';
import 'package:mazl/core/images/photo_cache.dart';

/// Une image qui arrive après un délai, comme un chargement depuis le disque.
class _SlowImage extends ImageProvider<_SlowImage> {
  _SlowImage(this.id, this.image);

  final String id;
  final ui.Image image;

  @override
  Future<_SlowImage> obtainKey(ImageConfiguration configuration) =>
      Future.value(this);

  @override
  ImageStreamCompleter loadImage(_SlowImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.delayed(
          const Duration(milliseconds: 20),
          () => ImageInfo(image: image.clone()),
        ),
      );

  @override
  bool operator ==(Object other) => other is _SlowImage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

void main() {
  group('photoCacheKey', () {
    const host = 'https://api.mazl.example';

    test('two signatures of the same photo share one key', () {
      final first = photoCacheKey('$host/media/photos/42?exp=1000&sig=aaa');
      final second = photoCacheKey('$host/media/photos/42?exp=4600&sig=bbb');
      expect(first, second);
      expect(first, '$host/media/photos/42');
    });

    test('another photo has another key', () {
      expect(
        photoCacheKey('$host/media/photos/42?exp=1&sig=a'),
        isNot(photoCacheKey('$host/media/photos/43?exp=1&sig=a')),
      );
    });

    test('chat images are keyed by their path too', () {
      expect(
        photoCacheKey('$host/media/chat/9?exp=1&sig=a'),
        photoCacheKey('$host/media/chat/9?exp=2&sig=b'),
      );
    });

    test('an external photo keeps its size parameters', () {
      const small = 'https://images.unsplash.com/photo-1?w=200&q=80';
      const large = 'https://images.unsplash.com/photo-1?w=1200&q=80';
      expect(photoCacheKey(small), isNot(photoCacheKey(large)));
      expect(
        photoCacheKey(small),
        photoCacheKey('https://images.unsplash.com/photo-1?q=80&w=200'),
      );
    });
  });

  group('MazlNetworkImage', () {
    late ui.Image pixel;

    setUp(() {
      MazlImageSeen.clear();
    });
    tearDown(() => debugImageProvider = null);

    Future<void> mount(WidgetTester tester, String url) async {
      debugImageProvider = (u, _) => _SlowImage(photoCacheKey(u), pixel);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 120,
            height: 120,
            child: MazlNetworkImage(key: UniqueKey(), url: url),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump(const Duration(milliseconds: 10));
    }

    testWidgets('fades in the first time, never again for the same photo', (
      tester,
    ) async {
      pixel = (await tester.runAsync(
        () => createTestImage(width: 4, height: 4),
      ))!;
      await mount(tester, 'https://x.example/media/photos/7?exp=1&sig=a');
      expect(
        find.byType(Opacity),
        findsOneWidget,
        reason: 'first appearance fades',
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.pumpWidget(const SizedBox());
      await mount(tester, 'https://x.example/media/photos/7?exp=99&sig=b');
      expect(
        find.byType(Opacity),
        findsNothing,
        reason: 'seen photo, new signature',
      );
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('a different photo still fades', (tester) async {
      pixel = (await tester.runAsync(
        () => createTestImage(width: 4, height: 4),
      ))!;
      await mount(tester, 'https://x.example/media/photos/7?exp=1&sig=a');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await mount(tester, 'https://x.example/media/photos/8?exp=1&sig=a');
      expect(find.byType(Opacity), findsOneWidget);
    });
  });
}
