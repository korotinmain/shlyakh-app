import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/app/app_shell.dart';
import 'package:shlyakh/features/history/presentation/history_screen.dart';
import 'package:shlyakh/features/path/presentation/path_screen.dart';
import 'package:shlyakh/features/today/presentation/today_screen.dart';

part 'router.g.dart';

/// Paths of the app's routes.
abstract final class AppRoutes {
  static const today = '/today';
  static const path = '/path';
  static const history = '/history';
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) => GoRouter(
  initialLocation: AppRoutes.today,
  routes: [
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
            ),
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
  ],
);
