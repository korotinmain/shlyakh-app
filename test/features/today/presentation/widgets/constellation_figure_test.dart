import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/theme.dart';
import 'package:shlyakh/features/path/domain/figure_state.dart';
import 'package:shlyakh/features/path/domain/sky_route.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';
import 'package:shlyakh/features/today/presentation/widgets/constellation_figure.dart';
import 'package:shlyakh/l10n/app_localizations.dart';

import '../../../../helpers/route_fixture.dart';

SkyPoint _at(double x, double y) => (hip: 1, x: x, y: y, mag: 1, ra: 0, dec: 0);

Future<void> _pumpFigure(
  WidgetTester tester, {
  required Size size,
  Brightness brightness = Brightness.dark,
}) async {
  final route = testRoute();
  final figure = figureStates(route, pathProgress(16870, route));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Center(
        child: SizedBox.fromSize(
          size: size,
          child: ConstellationFigure(
            constellation: route.constellations[figure.constellationIndex],
            figure: figure,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('figurePoint', () {
    const zone = Rect.fromLTWH(0, 0, 300, 200);

    test('fits the unit box into a padded square centred in the zone', () {
      // Square side 200 − 2 × 24 = 152, centred: x from 74, y from 24.
      expect(figurePoint(_at(0, 0), zone), const Offset(74, 24));
      expect(figurePoint(_at(1, 1), zone), const Offset(226, 176));
      expect(figurePoint(_at(0.5, 0.5), zone), const Offset(150, 100));
    });

    test('follows the zone offset', () {
      const moved = Rect.fromLTWH(10, 20, 200, 300);

      // Side 152, centred vertically: y from 20 + 74.
      expect(figurePoint(_at(0, 0), moved), const Offset(34, 94));
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('draws the figure and its name in the ${brightness.name} '
        'theme', (tester) async {
      await _pumpFigure(
        tester,
        size: const Size(300, 300),
        brightness: brightness,
      );

      expect(find.text('Vulpecula'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ConstellationFigure),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a zone with no height paints nothing and throws nothing', (
    tester,
  ) async {
    await _pumpFigure(tester, size: const Size(300, 0));

    expect(tester.takeException(), isNull);
    expect(find.text('Vulpecula'), findsNothing);
  });

  testWidgets('the figure is labelled with its name for VoiceOver', (
    tester,
  ) async {
    await _pumpFigure(tester, size: const Size(300, 300));

    expect(find.bySemanticsLabel('Vulpecula'), findsWidgets);
  });
}
