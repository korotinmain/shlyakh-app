import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/steps/data/demo/demo_steps_repository.dart';
import 'package:shlyakh/features/steps/domain/steps_repository.dart';

part 'steps_repository_provider.g.dart';

/// The steps source. The demo repository until the HealthKit → Drift
/// repository replaces it; no TestFlight build before that.
@Riverpod(keepAlive: true)
StepsRepository stepsRepository(Ref ref) =>
    DemoStepsRepository(ref.watch(clockProvider));
