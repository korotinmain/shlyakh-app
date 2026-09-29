import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/launch_screen.dart';
import 'package:shlyakh/app/theme.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/features/steps/presentation/providers/steps_providers.dart';

import '../helpers/pump_app.dart';

void main() {
  for (final (brightness, palette) in [
    (Brightness.dark, AppPalette.dark),
    (Brightness.light, AppPalette.light),
  ]) {
    testWidgets('the launch screen draws the ${brightness.name} sky', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Still loading: only the sky.
            journeyStartProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(brightness),
            home: const LaunchScreen(),
          ),
        ),
      );

      final gradients = [
        for (final box in tester.widgetList<DecoratedBox>(
          find.byType(DecoratedBox),
        ))
          if (box.decoration case BoxDecoration(:final LinearGradient gradient))
            gradient.colors,
      ];
      expect(gradients, contains(palette.sky));
      if (palette.backdrop == Backdrop.nebula) {
        final nebula = [
          for (final box in tester.widgetList<DecoratedBox>(
            find.byType(DecoratedBox),
          ))
            if (box.decoration case BoxDecoration(
              :final RadialGradient gradient,
            ))
              gradient.colors.first,
        ];
        expect(nebula, [palette.backdropTint]);
      }
    });
  }

  testWidgets('a journey start that fails to load shows why', (tester) async {
    await pumpApp(
      tester,
      journeyStarted: false,
      overrides: [
        journeyStartProvider.overrideWith(
          (ref) => Stream.error(const StorageFailure()),
        ),
      ],
    );

    expect(find.byType(LaunchScreen), findsOneWidget);
    expect(
      find.text(
        "Couldn't save your data on this device. Try restarting the app.",
      ),
      findsOneWidget,
    );
  });
}
