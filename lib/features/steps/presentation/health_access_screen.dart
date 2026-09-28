import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/app_radii.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/design/glass_panel.dart';
import 'package:shlyakh/core/design/status_bar.dart';
import 'package:shlyakh/core/error/failure_message.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/features/steps/presentation/providers/health_access.dart';
import 'package:shlyakh/features/today/presentation/widgets/sky_background.dart';

/// Shown until the journey starts: what the app reads from Health, and
/// the "Allow" button that shows the system prompt.
class HealthAccessScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = context.l10n;
    // A Scaffold gives the text its default style, like AppShell does for
    // the tabs; this route sits outside the shell.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyleFor(palette.brightness),
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: SkyBackground()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: GlassPanel(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.healthAccessTitle,
                            style: AppTypography.title,
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            l10n.healthAccessBody,
                            style: AppTypography.body,
                          ),
                          const SizedBox(height: AppSpacing.l),
                          _Action(
                            accent: palette.accent,
                            onAccent: palette.onAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends ConsumerWidget {
  const new({required this.accent, required this.onAccent});

  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final access = ref.watch(healthAccessProvider);
    return switch (ref.watch(healthAvailableProvider)) {
      AsyncValue(value: false) => Text(
        l10n.errorHealthUnavailable,
        style: AppTypography.body,
      ),
      AsyncValue(:final error?) => Text(
        failureMessage(l10n, error),
        style: AppTypography.body,
      ),
      AsyncValue(value: true) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (access case AsyncValue(:final error?, isLoading: false)) ...[
            Text(failureMessage(l10n, error), style: AppTypography.footnote),
            const SizedBox(height: AppSpacing.s),
          ],
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: onAccent,
              // Disabled while the prompt is on its way: the spinner keeps
              // the button's colours.
              disabledBackgroundColor: accent,
              disabledForegroundColor: onAccent,
              textStyle: AppTypography.headline,
              padding: const EdgeInsets.all(AppSpacing.m),
            ),
            onPressed: access.isLoading
                ? null
                : () => unawaited(
                    ref.read(healthAccessProvider.notifier).allow(),
                  ),
            child: access.isLoading
                ? SizedBox.square(
                    dimension: AppSpacing.l,
                    child: CircularProgressIndicator(color: onAccent),
                  )
                : Text(l10n.healthAccessAllow),
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
