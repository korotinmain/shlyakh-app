import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shlyakh/app/router.dart';
import 'package:shlyakh/app/theme.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/l10n/app_localizations.dart';

class App extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
