import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shlyakh/app/app.dart';
import 'package:shlyakh/app/error_handlers.dart';
import 'package:shlyakh/app/licenses.dart';
import 'package:shlyakh/core/logging/logger_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  // Created before runApp so unhandled errors are logged from the start.
  final container = ProviderContainer();
  final logger = container.read(loggerProvider);
  FlutterError.onError = flutterErrorHandler(
    logger,
    presentInDebug: kDebugMode,
  );
  PlatformDispatcher.instance.onError = platformErrorHandler(logger);

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
