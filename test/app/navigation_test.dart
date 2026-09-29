import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/path/presentation/path_screen.dart';

import '../helpers/pump_app.dart';

Finder _tab(String label) => find.descendant(
  of: find.byType(FloatingTabBar),
  matching: find.text(label),
);

void main() {
  testWidgets('the tab bar switches between Today and Path', (tester) async {
    await pumpApp(
      tester,
      overrides: [
        clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 9, 28, 12))),
      ],
    );

    expect(_tab('Today'), findsOneWidget);
    expect(find.byType(PathScreen), findsNothing);

    await tester.tap(_tab('Path'));
    await tester.pumpAndSettle();
    expect(find.byType(PathScreen), findsOneWidget);

    await tester.tap(_tab('Today'));
    await tester.pumpAndSettle();
    expect(find.byType(PathScreen), findsNothing);
    expect(_tab('History'), findsNothing);
  });

  for (final (brightness, icons) in [
    (Brightness.dark, Brightness.dark),
    (Brightness.light, Brightness.light),
  ]) {
    testWidgets(
      'the Path tab sets the status bar in the ${brightness.name} theme',
      (tester) async {
        await pumpApp(
          tester,
          brightness: brightness,
          overrides: [
            clockProvider.overrideWithValue(
              Clock.fixed(DateTime(2026, 9, 28, 12)),
            ),
          ],
        );
        await tester.tap(_tab('Path'));
        await tester.pumpAndSettle();

        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find
              .ancestor(
                of: find.byType(PathScreen),
                matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
              )
              .first,
        );
        // statusBarBrightness is the brightness of what is behind the bar:
        // dark means light icons.
        expect(region.value.statusBarBrightness, icons);
      },
    );
  }
}
