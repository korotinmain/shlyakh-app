import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/features/home/presentation/home_screen.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) => GoRouter(
  routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
);
