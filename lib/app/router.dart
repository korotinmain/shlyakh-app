import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/app/app_shell.dart';
import 'package:shlyakh/features/history/presentation/history_screen.dart';
import 'package:shlyakh/features/path/presentation/path_screen.dart';
import 'package:shlyakh/features/steps/domain/journey_start.dart';
import 'package:shlyakh/features/steps/presentation/health_access_screen.dart';
import 'package:shlyakh/features/steps/presentation/providers/steps_providers.dart';
import 'package:shlyakh/features/today/presentation/today_screen.dart';

part 'router.g.dart';

/// Paths of the app's routes.
abstract final class AppRoutes {
  static const today = '/today';
  static const path = '/path';
  static const history = '/history';
  static const healthAccess = '/health-access';
}

/// Where to send [location] for the journey state: the access screen until
/// the journey starts, Today once it has; unchanged while it loads.
String? healthAccessRedirect(
  AsyncValue<JourneyStart?> journey,
  String location,
) {
  if (!journey.hasValue) return null;
  final started = journey.value != null;
  final onAccess = location == AppRoutes.healthAccess;
  if (!started && !onAccess) return AppRoutes.healthAccess;
  if (started && onAccess) return AppRoutes.today;
  return null;
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
    initialLocation: AppRoutes.today,
    refreshListenable: journey,
    redirect: (_, state) =>
        healthAccessRedirect(journey.value, state.matchedLocation),
    routes: _routes,
  );
  ref.onDispose(router.dispose);
  return router;
}

final List<RouteBase> _routes = [
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
          GoRoute(path: AppRoutes.path, builder: (_, _) => const PathScreen()),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.history,
            builder: (_, _) => const HistoryScreen(),
          ),
        ],
      ),
    ],
  ),
];
