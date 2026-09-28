import 'dart:io';

import 'package:shlyakh/features/path/data/route_asset.dart';
import 'package:shlyakh/features/path/domain/sky_route.dart';

/// The bundled route, read from the asset file.
SkyRoute testRoute() =>
    parseRouteAsset(File('assets/sky/route.json').readAsStringSync());
