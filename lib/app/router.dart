import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/app/app_shell.dart';
import 'package:shlyakh/app/launch_screen.dart';
import 'package:shlyakh/features/path/presentation/path_map_screen.dart';
import 'package:shlyakh/features/path/presentation/path_screen.dart';
import 'package:shlyakh/features/steps/domain/journey_start.dart';
import 'package:shlyakh/features/steps/presentation/health_access_screen.dart';
import 'package:shlyakh/features/steps/presentation/providers/steps_providers.dart';
import 'package:shlyakh/features/today/presentation/today_screen.dart';

part 'router.g.dart';

/// Paths of the app's routes.
abstract final class AppRoutes {
  /// Only the sky, while the journey start loads on launch.
  static const launch = '/';
  static const today = '/today';
  static const path = '/path';
  static const pathMap = '/path/map';
  static const healthAccess = '/health-access';
}

/// Where to send [location] for the journey state: the access screen until
/// the journey starts, Today once it has. While it loads the app stays on
/// the launch route, which shows only the sky, so a new user never sees
/// the Today shell before the access screen; if it fails to load, the
/// launch route shows the failure.
String? healthAccessRedirect(
  AsyncValue<JourneyStart?> journey,
  String location,
) {
  if (!journey.hasValue) return null;
  final started = journey.value != null;
  if (!started) {
    return location == AppRoutes.healthAccess ? null : AppRoutes.healthAccess;
  }
  final waiting =
      location == AppRoutes.launch || location == AppRoutes.healthAccess;
  return waiting ? AppRoutes.today : null;
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final journey = ValueNotifier<AsyncValue<JourneyStart?>>(
    const AsyncLoading(),
  );
  ref
    ..onDispose(journey.dispose)
    ..listen(
      journeyStartProvider,
      (_, next) => journey.value = next,
      fireImmediately: true,
    );
  final router = GoRouter(
    initialLocation: AppRoutes.launch,
    refreshListenable: journey,
    redirect: (_, state) =>
        healthAccessRedirect(journey.value, state.matchedLocation),
    routes: _routes,
  );
  ref.onDispose(router.dispose);
  return router;
}

final List<RouteBase> _routes = [
  GoRoute(path: AppRoutes.launch, builder: (_, _) => const LaunchScreen()),
  GoRoute(
    path: AppRoutes.healthAccess,
    builder: (_, _) => const HealthAccessScreen(),
  ),
  StatefulShellRoute.indexedStack(
    builder: (_, _, shell) => AppShell(shell: shell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.today,
            builder: (_, _) => const TodayScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.path,
            builder: (_, _) => const PathScreen(),
            routes: [
              GoRoute(path: 'map', builder: (_, _) => const PathMapScreen()),
            ],
          ),
        ],
      ),
    ],
  ),
];
