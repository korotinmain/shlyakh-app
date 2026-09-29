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

  group('figureBounds', () {
    test('wraps the placed stars', () {
      const zone = Rect.fromLTWH(0, 0, 300, 200);

      expect(
        figureBounds([_at(0, 0.25), _at(1, 0.75)], zone),
        Rect.fromPoints(
          figurePoint(_at(0, 0.25), zone),
          figurePoint(_at(1, 0.75), zone),
        ),
      );
    });
  });

  testWidgets('the name sits just under the stars, not at the zone bottom', (
    tester,
  ) async {
    await _pumpFigure(tester, size: const Size(300, 500));

    final route = testRoute();
    final vulpecula = route.constellations[1];
    // The stars are drawn in the painter's box, above the name's room.
    final zone = tester.getRect(
      find
          .descendant(
            of: find.byType(ConstellationFigure),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    final stars = figureBounds(vulpecula.stars, zone);
    final name = tester.getRect(find.text('Vulpecula'));
    expect(name.top, greaterThan(stars.bottom));
    expect(name.top - stars.bottom, lessThanOrEqualTo(40));
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

  for (final height in [70.0, 120.0]) {
    testWidgets('a zone ${height.toInt()} high draws the stars without the '
        'name rather than the name alone', (tester) async {
      await _pumpFigure(tester, size: Size(300, height));

      expect(tester.takeException(), isNull);
      expect(find.text('Vulpecula'), findsNothing);
      final painter = tester.getRect(
        find
            .descendant(
              of: find.byType(ConstellationFigure),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(painter.height, height);
    });
  }

  testWidgets('a zone with room for a 48 pt figure shows the name too', (
    tester,
  ) async {
    // 48 + 2 × 24 padding + 48 for the name.
    await _pumpFigure(tester, size: const Size(300, 144));

    expect(find.text('Vulpecula'), findsOneWidget);
  });

  testWidgets('the figure is labelled with its name for VoiceOver', (
    tester,
  ) async {
    await _pumpFigure(tester, size: const Size(300, 300));

    expect(find.bySemanticsLabel('Vulpecula'), findsWidgets);
  });
}
