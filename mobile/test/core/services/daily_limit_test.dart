import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/daily_limit.dart';

void main() {
  group('timeUntilMidnight', () {
    test('23:59:30 -> 30 secondes avant minuit', () {
      final left = timeUntilMidnight(DateTime(2026, 10, 23, 23, 59, 30));
      expect(left, const Duration(seconds: 30));
      expect(formatCountdown(left), '00:00:30');
    });

    test('à minuit pile, il reste une journée entière', () {
      final left = timeUntilMidnight(DateTime(2026, 10, 23));
      expect(left, const Duration(hours: 24));
    });

    test('en milieu de journée', () {
      final left = timeUntilMidnight(DateTime(2026, 10, 23, 19, 47, 27));
      expect(formatCountdown(left), '04:12:33');
    });

    test('passe correctement la fin du mois et de l\'année', () {
      expect(
        timeUntilMidnight(DateTime(2026, 12, 31, 23, 0)),
        const Duration(hours: 1),
      );
      expect(
        timeUntilMidnight(DateTime(2026, 2, 28, 22, 30)),
        const Duration(hours: 1, minutes: 30),
      );
    });
  });

  group('formatCountdown', () {
    test('complète avec des zéros', () {
      expect(formatCountdown(const Duration(seconds: 5)), '00:00:05');
      expect(
        formatCountdown(const Duration(hours: 3, minutes: 4, seconds: 9)),
        '03:04:09',
      );
    });

    test('ne descend jamais sous zéro', () {
      expect(formatCountdown(const Duration(seconds: -4)), '00:00:00');
    });
  });
}
