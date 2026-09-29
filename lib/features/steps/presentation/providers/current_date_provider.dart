import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

part 'current_date_provider.g.dart';

/// Today's local date; changes at local midnight, so screens move to the
/// new day even when no new steps arrive.
@riverpod
LocalDate currentDate(Ref ref) {
  final now = ref.watch(clockProvider).now();
  // DateTime normalizes day + 1, and a local midnight is safe across DST.
  final midnight = DateTime(now.year, now.month, now.day + 1);
  final timer = Timer(midnight.difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return LocalDate.fromDateTime(now);
}
