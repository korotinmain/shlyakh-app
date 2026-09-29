import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shlyakh/core/design/app_radii.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/design/glass_panel.dart';
import 'package:shlyakh/core/error/failure_message.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/features/steps/presentation/providers/steps_providers.dart';
import 'package:shlyakh/features/today/presentation/widgets/sky_background.dart';

/// Only the sky: shown for the moment the journey start loads on launch,
/// before the router picks the access screen or Today. If the start fails
/// to load, the router has nowhere to go, so this screen says why.
class LaunchScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(journeyStartProvider).error;
    // A Scaffold gives the text its default style; this route sits
    // outside the shell.
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SkyBackground()),
          if (error != null)
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: GlassPanel(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Text(
                        failureMessage(context.l10n, error),
                        style: AppTypography.body,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
