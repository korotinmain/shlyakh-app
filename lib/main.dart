import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shlyakh/app/app.dart';
import 'package:shlyakh/app/error_handlers.dart';
import 'package:shlyakh/app/licenses.dart';
import 'package:shlyakh/core/logging/logger_provider.dart';
import 'package:shlyakh/features/steps/data/healthkit/steps_api.g.dart';
import 'package:shlyakh/features/steps/presentation/providers/steps_providers.dart';
import 'package:shlyakh/features/steps/presentation/steps_events_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerLicenses();
  // Created before runApp so unhandled errors are logged from the start.
  final container = ProviderContainer();
  final logger = container.read(loggerProvider);
  FlutterError.onError = flutterErrorHandler(
    logger,
    presentInDebug: kDebugMode,
  );
  PlatformDispatcher.instance.onError = platformErrorHandler(logger);
  // Before runApp: a HealthKit background relaunch sends its wakeup early,
  // and the channel holds it until this handler exists.
  StepsEventsApi.setUp(
    StepsEventsHandler(
      sync: () => container.read(stepsSyncProvider).sync(),
      logger: logger,
    ),
  );

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
