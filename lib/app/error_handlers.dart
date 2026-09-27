import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shlyakh/core/logging/app_logger.dart';

/// Routes framework errors (build, layout, paint) to [logger]; in debug
/// builds Flutter's own report is shown as well.
FlutterExceptionHandler flutterErrorHandler(
  AppLogger logger, {
  required bool presentInDebug,
}) => (details) {
  logger.error(details.exception, details.stack ?? StackTrace.empty);
  if (presentInDebug) FlutterError.presentError(details);
};

/// Routes uncaught asynchronous errors to [logger] and reports them as
/// handled, so they neither disappear nor crash the app.
ErrorCallback platformErrorHandler(AppLogger logger) => (error, stackTrace) {
  logger.error(error, stackTrace);
  return true;
};
