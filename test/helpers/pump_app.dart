import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/app.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/features/steps/data/healthkit/steps_api.g.dart';

import 'steps_test_overrides.dart';

/// Pumps the whole app as the system would launch it.
///
/// [systemLocales] simulates the device's preferred languages, so tests go
/// through Flutter's real locale resolution instead of forcing a locale.
///
/// The app gets an in-memory [db] and a mock HealthKit [api] unless the
/// test passes its own; with [journeyStarted] the `'local'` journey has
/// begun, so the app opens on Today. [overrides] win over the defaults.
/// [brightness] is the system appearance (light unless given).
Future<void> pumpApp(
  WidgetTester tester, {
  List<Locale> systemLocales = const [Locale('en')],
  List<Override> overrides = const [],
  AppDatabase? db,
  StepsHostApi? api,
  bool journeyStarted = true,
  Brightness brightness = Brightness.light,
}) async {
  tester.platformDispatcher.localesTestValue = systemLocales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  final database = db ?? memoryDatabase();
  if (db == null) addTearDown(database.close);
  if (journeyStarted) {
    await tester.runAsync(() => startTestJourney(database));
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...stepsTestOverrides(db: database, api: api ?? MockStepsHostApi()),
        ...overrides,
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}
