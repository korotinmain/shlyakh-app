import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The committed sky asset (docs/decisions/0009-sky-data.md) against the
/// spec (docs/superpowers/specs/2026-09-28-constellation-path-design.md).
void main() {
  final asset = jsonDecode(
    File('assets/sky/route.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final route = asset['route']! as Map<String, Object?>;
  final constellations = (asset['constellations']! as Map)
      .cast<String, Map<String, Object?>>();

  List<Map<String, Object?>> starsOf(String id) =>
      (constellations[id]!['stars']! as List).cast<Map<String, Object?>>();

  test('the main route follows the Milky Way from Sagitta', () {
    expect(route['main'], [
      'Sge', 'Vul', 'Cyg', 'Lac', 'Cep', 'Cas', 'Per', //
      'Aur', 'Tau', 'Gem', 'Ori', 'Mon', 'CMa',
    ]);
  });

  test('the branch goes to the heart of the Galaxy', () {
    expect(route['branch'], ['Aql', 'Sct', 'Sgr']);
  });

  test('star counts match the spec', () {
    const expected = {
      'Sge': 4, 'Vul': 5, 'Cyg': 9, 'Lac': 9, 'Cep': 10, 'Cas': 5, //
      'Per': 23, 'Aur': 9, 'Tau': 12, 'Gem': 12, 'Ori': 23, 'Mon': 9,
      'CMa': 11, 'Aql': 8, 'Sct': 4, 'Sgr': 25,
    };
    expect({for (final id in expected.keys) id: starsOf(id).length}, expected);
  });

  test('every figure is well formed', () {
    for (final MapEntry(key: id, value: c) in constellations.entries) {
      final count = starsOf(id).length;
      final order = (c['order']! as List).cast<int>();
      expect(order.toSet(), {for (var i = 0; i < count; i++) i}, reason: id);
      expect(order, hasLength(count), reason: id);
      for (final line in (c['lines']! as List).cast<List<Object?>>()) {
        for (final index in line.cast<int>()) {
          expect(index, inInclusiveRange(0, count - 1), reason: id);
        }
      }
      for (final star in starsOf(id)) {
        expect(star['x']! as num, inInclusiveRange(0, 1), reason: id);
        expect(star['y']! as num, inInclusiveRange(0, 1), reason: id);
      }
    }
  });

  test('Elnath is in both Auriga and Taurus', () {
    bool hasElnath(String id) => starsOf(id).any((s) => s['hip'] == 25428);
    expect(hasElnath('Aur'), isTrue);
    expect(hasElnath('Tau'), isTrue);
  });

  test('the main route has 141 figure stars, 140 distinct', () {
    final main = (route['main']! as List).cast<String>();
    final all = [for (final id in main) ...starsOf(id).map((s) => s['hip'])];
    expect(all, hasLength(141));
    expect(all.toSet(), hasLength(140));
  });
}
