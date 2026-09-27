// coverage:ignore-file
// Reason: DI wiring; tests override loggerProvider.
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/logging/app_logger.dart';

part 'logger_provider.g.dart';

@Riverpod(keepAlive: true)
AppLogger logger(Ref ref) => const DeveloperLogger(enabled: kDebugMode);
