import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/router.dart';
import 'package:shlyakh/features/steps/domain/journey_start.dart';

final JourneyStart _start = (
  userId: 'local',
  startedAt: DateTime.utc(2026, 9),
  timezone: 'Europe/Kyiv',
);

void main() {
  test('stays on the launch route while the journey loads', () {
    expect(
      healthAccessRedirect(const AsyncLoading(), AppRoutes.launch),
      isNull,
    );
  });

  test('from the launch route to the access screen before the journey', () {
    expect(
      healthAccessRedirect(const AsyncData(null), AppRoutes.launch),
      AppRoutes.healthAccess,
    );
  });

  test('from the launch route to Today once the journey started', () {
    expect(
      healthAccessRedirect(AsyncData(_start), AppRoutes.launch),
      AppRoutes.today,
    );
  });

  test('keeps a tab once the journey started', () {
    expect(healthAccessRedirect(AsyncData(_start), AppRoutes.path), isNull);
  });

  test('leaves the access screen once the journey started', () {
    expect(
      healthAccessRedirect(AsyncData(_start), AppRoutes.healthAccess),
      AppRoutes.today,
    );
  });
}
