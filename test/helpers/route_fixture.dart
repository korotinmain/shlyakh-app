import 'dart:io';

import 'package:shlyakh/features/path/data/route_asset.dart';
import 'package:shlyakh/features/path/domain/route.dart';

/// The bundled route, read from the asset file.
Route testRoute() =>
    parseRouteAsset(File('assets/sky/route.json').readAsStringSync());
