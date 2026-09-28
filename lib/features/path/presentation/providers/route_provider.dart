import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/features/path/data/route_asset.dart';
import 'package:shlyakh/features/path/domain/route.dart';

part 'route_provider.g.dart';

/// The constellation route, loaded once from the bundled asset.
@Riverpod(keepAlive: true)
Future<Route> route(Ref ref) => loadRouteAsset(rootBundle);
