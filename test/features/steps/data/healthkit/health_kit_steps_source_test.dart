import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/features/steps/data/healthkit/health_kit_steps_source.dart';
import 'package:shlyakh/features/steps/data/healthkit/steps_api.g.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

class _Api extends Mock implements StepsHostApi;

void main() {
  late _Api api;
  late HealthKitStepsSource source;

  setUp(() {
    api = _Api();
    source = HealthKitStepsSource(api);
    when(() => api.timeZoneId()).thenAnswer((_) async => 'Europe/Kyiv');
  });

  group('dailySteps', () {
    test('maps native days', () async {
      when(() => api.dailySteps(any())).thenAnswer(
        (_) async => [NativeDay(localDate: '2026-09-28', steps: 6870)],
      );

      final days = await source.dailySteps(
        userId: 'local',
        from: DateTime.utc(2026, 9, 28),
      );

      expect(days, [
        (
          userId: 'local',
          localDate: LocalDate.parse('2026-09-28'),
          timezone: 'Europe/Kyiv',
          steps: 6870,
        ),
      ]);
    });

    test('passes the start as epoch ms', () async {
      when(() => api.dailySteps(any())).thenAnswer((_) async => []);

      await source.dailySteps(
        userId: 'local',
        from: DateTime.utc(2026, 9, 28, 15, 30),
      );

      verify(() => api.dailySteps(1790609400000)).called(1);
    });

    test('with no days returns an empty list', () async {
      when(() => api.dailySteps(any())).thenAnswer((_) async => []);

      final days = await source.dailySteps(
        userId: 'local',
        from: DateTime.utc(2026, 9, 29),
      );

      expect(days, isEmpty);
    });

    test('locked maps to HealthDataLocked', () async {
      final error = PlatformException(code: 'locked');
      when(() => api.dailySteps(any())).thenThrow(error);

      await expectLater(
        source.dailySteps(userId: 'local', from: DateTime.utc(2026, 9, 28)),
        throwsA(isA<HealthDataLocked>().having((f) => f.cause, 'cause', error)),
      );
    });
  });

  group('unavailable maps to HealthUnavailable', () {
    test('from requestAccess', () async {
      when(() => api.requestAccess())
          .thenThrow(PlatformException(code: 'unavailable'));

      await expectLater(
        source.requestAccess(),
        throwsA(isA<HealthUnavailable>()),
      );
    });

    test('from isAvailable', () async {
      when(() => api.isAvailable())
          .thenThrow(PlatformException(code: 'unavailable'));

      await expectLater(
        source.isAvailable(),
        throwsA(isA<HealthUnavailable>()),
      );
    });
  });

  test('a HealthKit error maps to UnexpectedFailure', () async {
    final error = PlatformException(code: 'healthkit', details: 3);
    when(() => api.dailySteps(any())).thenThrow(error);

    await expectLater(
      source.dailySteps(userId: 'local', from: DateTime.utc(2026, 9, 28)),
      throwsA(isA<UnexpectedFailure>().having((f) => f.cause, 'cause', error)),
    );
  });

  test('an undocumented code is rethrown', () async {
    when(() => api.dailySteps(any()))
        .thenThrow(PlatformException(code: 'channel-error'));

    await expectLater(
      source.dailySteps(userId: 'local', from: DateTime.utc(2026, 9, 28)),
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'channel-error'),
      ),
    );
  });

  test('isAvailable and timeZoneId pass the native values through', () async {
    when(() => api.isAvailable()).thenAnswer((_) async => true);

    expect(await source.isAvailable(), isTrue);
    expect(await source.timeZoneId(), 'Europe/Kyiv');
  });
}
