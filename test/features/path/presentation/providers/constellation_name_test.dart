import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/presentation/providers/constellation_name.dart';
import 'package:shlyakh/l10n/app_localizations.dart';

import '../../../../helpers/route_fixture.dart';

void main() {
  final uk = lookupAppLocalizations(const Locale('uk'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('constellationName', () {
    test('names every route constellation in uk and en', () {
      for (final c in testRoute().constellations) {
        expect(constellationName(uk, c.id), isNotEmpty, reason: c.id);
        expect(constellationName(en, c.id), isNotEmpty, reason: c.id);
        expect(
          constellationName(uk, c.id),
          isNot(constellationName(en, c.id)),
          reason: c.id,
        );
      }
    });

    test('uses the Ukrainian and Latin names', () {
      expect(constellationName(uk, 'Sge'), 'Стріла');
      expect(constellationName(en, 'Sge'), 'Sagitta');
      expect(constellationName(uk, 'CMa'), 'Великий Пес');
      expect(constellationName(en, 'CMa'), 'Canis Major');
      expect(constellationName(uk, 'Sgr'), 'Стрілець');
    });

    test('rejects an unknown id', () {
      expect(() => constellationName(en, 'UMa'), throwsArgumentError);
    });
  });
}
