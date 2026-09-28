import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/data/route_asset.dart';
import 'package:shlyakh/features/path/domain/sky_route.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';

import '../../../helpers/route_fixture.dart';

const _elnath = 25428;

Map<String, Object?> _asset() =>
    jsonDecode(File('assets/sky/route.json').readAsStringSync())
        as Map<String, Object?>;

Matcher _throwsNaming(String text) => throwsA(
  isA<RouteException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  group('parseRouteAsset on the bundled route', () {
    final route = testRoute();
    final ids = [for (final c in route.constellations) c.id];

    test('has the main route, then the branch', () {
      expect(ids, [
        'Sge', 'Vul', 'Cyg', 'Lac', 'Cep', 'Cas', 'Per', //
        'Aur', 'Tau', 'Gem', 'Ori', 'Mon', 'CMa', 'Aql', 'Sct', 'Sgr',
      ]);
      expect(route.mainLength, 13);
    });

    test('lights 140 stars on the main route and 177 in all', () {
      expect(route.stars, hasLength(177));
      expect(
        route.stars.where((s) => s.constellationIndex < 13),
        hasLength(140),
      );
    });

    test('lights Elnath in Auriga, not again in Taurus', () {
      expect(route.ownerOf(_elnath), ids.indexOf('Aur'));
      expect(route.ownOrder(ids.indexOf('Tau')), hasLength(11));
      expect(route.stars.where((s) => s.hip == _elnath), hasLength(1));
    });

    test('marks Taurus, Gemini and Orion at the edge of the Milky Way', () {
      expect(
        [
          for (final c in route.constellations)
            if (c.milkyWay == MilkyWay.edge) c.id,
        ],
        ['Tau', 'Gem', 'Ori'],
      );
    });

    test('keeps positions, lines and sky placement', () {
      final sge = route.constellations.first;

      expect(sge.stars, hasLength(4));
      expect(sge.lines, isNotEmpty);
      expect(sge.spanDeg, lessThan(10));
      expect(sge.centre.ra, inInclusiveRange(290, 300));
    });

    test('puts 16 870 XP on the first star of Vulpecula', () {
      final progress = pathProgress(16870, route);

      expect(progress.starsLit, 4);
      final next = progress.next!;
      expect((next.constellationIndex, next.starInConstellation), (1, 0));
      expect((next.xpIntoStar, next.xpForStar), (1870, 7500));
    });
  });

  group('parseRouteAsset rejects', () {
    test('an asset without a route', () {
      final asset = _asset()..remove('route');

      expect(() => parseRouteAsset(jsonEncode(asset)), _throwsNaming('route'));
    });

    test('a route id without a constellation', () {
      final asset = _asset();
      (asset['constellations']! as Map).remove('Cyg');

      expect(() => parseRouteAsset(jsonEncode(asset)), _throwsNaming('Cyg'));
    });

    test('a star without a HIP id', () {
      final asset = _asset();
      final sge = (asset['constellations']! as Map)['Sge'] as Map;
      ((sge['stars']! as List).first as Map).remove('hip');

      expect(() => parseRouteAsset(jsonEncode(asset)), _throwsNaming('Sge'));
    });

    test('text that is not JSON', () {
      expect(() => parseRouteAsset('{'), throwsA(isA<RouteException>()));
    });
  });
}
