import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/navigation/widgets/nav_bar_collapse.dart';

/// Scrolls are fed as (delta, pixels, time). Positive delta = content moves
/// up = the user scrolls DOWN the page.
class _Scroller {
  _Scroller(this.controller);

  final NavBarCollapseController controller;
  double pixels = 0;
  Duration time = Duration.zero;

  void scroll(
    double delta, {
    Duration every = const Duration(milliseconds: 16),
  }) {
    time += every;
    pixels = (pixels + delta).clamp(0, 10000);
    controller.onScroll(
      delta: delta,
      pixels: pixels,
      minExtent: 0,
      timestamp: time,
    );
  }

  void down(double total, {double step = 10}) {
    for (var done = 0.0; done < total; done += step) {
      scroll(step);
    }
  }
}

void main() {
  late NavBarCollapseController controller;
  late _Scroller s;

  setUp(() {
    controller = NavBarCollapseController();
    s = _Scroller(controller);
  });

  test('starts expanded', () {
    expect(controller.collapsed, isFalse);
  });

  test('a small scroll down keeps the bar expanded', () {
    s.down(30);
    expect(controller.collapsed, isFalse);
  });

  test('scrolling down past the threshold folds the bar', () {
    s.down(NavBarCollapseController.collapseDistance + 10);
    expect(controller.collapsed, isTrue);
  });

  test('a slow scroll back up keeps it folded', () {
    s.down(400);
    // 4 px every 16 ms = 250 px/s: reading, not a flick.
    for (var i = 0; i < 20; i++) {
      s.scroll(-4);
    }
    expect(controller.collapsed, isTrue);
  });

  test('a fast scroll back up unfolds it', () {
    s.down(400);
    // 30 px every 16 ms ≈ 1900 px/s.
    s.scroll(-30);
    s.scroll(-30);
    expect(controller.collapsed, isFalse);
  });

  test('reaching the top of the page unfolds it, however slowly', () {
    s.down(100);
    expect(controller.collapsed, isTrue);
    for (var i = 0; i < 50; i++) {
      s.scroll(-2);
    }
    expect(s.pixels, 0);
    expect(controller.collapsed, isFalse);
  });

  test('a long pause between two updates is not read as a fast scroll', () {
    s.down(400);
    s.scroll(-40, every: const Duration(seconds: 1)); // 40 px/s
    expect(controller.collapsed, isTrue);
  });

  test('changing direction resets the distance needed to fold', () {
    s.down(30);
    s.scroll(-5, every: const Duration(milliseconds: 100));
    s.down(30);
    expect(controller.collapsed, isFalse);
  });

  test('expand() unfolds and notifies once', () {
    s.down(400);
    var notified = 0;
    controller.addListener(() => notified++);
    controller.expand();
    controller.expand();
    expect(controller.collapsed, isFalse);
    expect(notified, 1);
  });

  test('after expand(), scrolling down folds it again', () {
    s.down(400);
    controller.expand();
    s.down(NavBarCollapseController.collapseDistance + 10);
    expect(controller.collapsed, isTrue);
  });
}
