// Reads the bundled route asset built by tool/sky/build_route.dart
// (docs/decisions/0009-sky-data.md).
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shlyakh/features/path/domain/sky_route.dart';

/// Path of the bundled route asset.
const routeAssetPath = 'assets/sky/route.json';

/// Constellations at the edge of the Milky Way band; the rest lie in it
/// (docs/superpowers/specs/2026-09-28-constellation-path-design.md).
const _edge = {'Tau', 'Gem', 'Ori'};

/// Loads the route from [bundle].
///
/// Throws [RouteException] when the asset is malformed.
Future<SkyRoute> loadRouteAsset(AssetBundle bundle) async =>
    parseRouteAsset(await bundle.loadString(routeAssetPath));

/// The route in [json], the contents of `assets/sky/route.json`.
///
/// Throws [RouteException] naming what failed when a key is missing or has
/// the wrong type.
SkyRoute parseRouteAsset(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (e) {
    throw RouteException('route asset is not JSON: ${e.message}');
  }
  final asset = _map(decoded, 'route asset');
  final order = _map(asset['route'], 'route');
  final main = _ids(order['main'], 'route.main');
  final branch = _ids(order['branch'], 'route.branch');
  final constellations = _map(asset['constellations'], 'constellations');
  return SkyRoute(
    constellations: [
      for (final id in [...main, ...branch])
        _constellation(id, constellations[id]),
    ],
    mainLength: main.length,
  );
}

Constellation _constellation(String id, Object? value) {
  try {
    final c = _map(value, 'constellation');
    final centre = _map(c['centre'], 'centre');
    return Constellation(
      id: id,
      stars: [for (final s in _list(c['stars'], 'stars')) _star(s)],
      lines: [
        for (final line in _list(c['lines'], 'lines'))
          switch (line) {
            [final int a, final int b] => (a, b),
            _ => throw RouteException('bad line $line'),
          },
      ],
      order: [for (final i in _list(c['order'], 'order')) _int(i, 'order')],
      milkyWay: _edge.contains(id) ? MilkyWay.edge : MilkyWay.inside,
      centre: (ra: _num(centre['ra'], 'ra'), dec: _num(centre['dec'], 'dec')),
      spanDeg: _num(c['spanDeg'], 'spanDeg'),
    );
  } on RouteException catch (e) {
    throw RouteException('$id: ${e.message}');
  }
}

SkyPoint _star(Object? value) {
  final s = _map(value, 'star');
  return (
    hip: _int(s['hip'], 'hip'),
    x: _num(s['x'], 'x'),
    y: _num(s['y'], 'y'),
    mag: _num(s['mag'], 'mag'),
    ra: _num(s['ra'], 'ra'),
    dec: _num(s['dec'], 'dec'),
  );
}

Map<String, Object?> _map(Object? value, String what) => switch (value) {
  final Map<String, Object?> map => map,
  _ => throw RouteException('$what is missing or not an object'),
};

List<Object?> _list(Object? value, String what) => switch (value) {
  final List<Object?> list => list,
  _ => throw RouteException('$what is missing or not a list'),
};

List<String> _ids(Object? value, String what) => [
  for (final id in _list(value, what))
    switch (id) {
      final String id => id,
      _ => throw RouteException('$what has a non-string id'),
    },
];

int _int(Object? value, String what) => switch (value) {
  final int i => i,
  _ => throw RouteException('$what is missing or not an integer'),
};

double _num(Object? value, String what) => switch (value) {
  final num n => n.toDouble(),
  _ => throw RouteException('$what is missing or not a number'),
};
