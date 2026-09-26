import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/app.dart';

/// Pumps the whole app as the system would launch it.
///
/// [systemLocales] simulates the device's preferred languages, so tests go
/// through Flutter's real locale resolution instead of forcing a locale.
Future<void> pumpApp(
  WidgetTester tester, {
  List<Locale> systemLocales = const [Locale('en')],
  List<Override> overrides = const [],
}) async {
  tester.platformDispatcher.localesTestValue = systemLocales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: const App()),
  );
  await tester.pumpAndSettle();
}
