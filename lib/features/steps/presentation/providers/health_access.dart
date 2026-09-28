import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/database/app_database_provider.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/steps/presentation/providers/steps_providers.dart';
import 'package:shlyakh/features/today/presentation/providers/current_user_provider.dart';

part 'health_access.g.dart';

/// Whether HealthKit exists on this device (not on some iPads).
@riverpod
Future<bool> healthAvailable(Ref ref) =>
    ref.watch(healthKitStepsSourceProvider).isAvailable();

/// The "Allow" action of the Health access screen: the tap starts the
/// journey (docs/superpowers/specs/2026-09-28-healthkit-steps-sync-design.md).
@Riverpod(keepAlive: true)
class HealthAccess extends _$HealthAccess {
  Future<void>? _allowing;

  @override
  FutureOr<void> build() {}

  /// Asks for access, then stores the journey start at the moment of the
  /// tap and runs the first sync. A tap while one is in progress joins it.
  /// Failures end up in the state; no start is stored if the prompt fails.
  Future<void> allow() =>
      _allowing ??= _allow().whenComplete(() => _allowing = null);

  Future<void> _allow() async {
    final tappedAt = ref.read(clockProvider).now().toUtc();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final source = ref.read(healthKitStepsSourceProvider);
      if (!await source.isAvailable()) throw const HealthUnavailable();
      await source.requestAccess();
      await ref.read(appDatabaseProvider).journeyStartDao.insertOnce((
        userId: ref.read(currentUserIdProvider),
        startedAt: tappedAt,
        timezone: await source.timeZoneId(),
      ));
      await ref.read(stepsSyncProvider).sync();
    });
  }
}
