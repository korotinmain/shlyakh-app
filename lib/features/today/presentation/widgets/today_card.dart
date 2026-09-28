import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/app_radii.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/design/glass.dart';
import 'package:shlyakh/core/design/glass_panel.dart';
import 'package:shlyakh/core/error/failure_message.dart';
import 'package:shlyakh/core/l10n/format_extension.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/features/today/presentation/providers/today_view.dart';
import 'package:shlyakh/features/today/presentation/widgets/progress_ring.dart';
import 'package:shlyakh/features/today/presentation/widgets/text_placeholder.dart';

/// Diameter of the progress ring, in logical pixels.
const double _ringSize = 72;

/// Width of the loading placeholders, in logical pixels.
const double _numberPlaceholderWidth = 120;
const double _captionPlaceholderWidth = 180;

/// The glass card: the current star's ring and today's steps.
class TodayCard extends StatelessWidget {
  const new({required this.view, super.key});

  final AsyncValue<TodayView> view;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = palette.onGlass;
    final track = foreground.withValues(alpha: GlassStyle.trackOpacity);
    return GlassPanel(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        // Riverpod retries a failed provider: while it does, the state is
        // loading but still carries the error, so check the error first.
        child: switch (view) {
          AsyncValue(:final error?) => Text(
            failureMessage(context.l10n, error),
            style: AppTypography.body,
          ),
          AsyncValue(:final value?) => _Content(
            view: value,
            accent: palette.accent,
            track: track,
          ),
          _ => _Loading(track: track),
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const new({required this.view, required this.accent, required this.track});

  final TodayView view;
  final Color accent;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final today = view.week.firstWhere((d) => d.isToday).date;
    return Row(
      children: [
        SizedBox.square(
          dimension: _ringSize,
          child: ProgressRing(
            fraction: view.starPercent / 100,
            arc: accent,
            track: track,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                context.l10n.percentValue(view.starPercent),
                style: tabular(AppTypography.headline),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.formatInt(view.steps),
                  style: tabular(AppTypography.display),
                ),
              ),
              Text(
                context.l10n.todayStepsLabel(view.steps),
                style: AppTypography.footnote,
              ),
              Text(
                context.formatLongDate(
                  DateTime(today.year, today.month, today.day),
                ),
                style: AppTypography.footnote.copyWith(
                  color: DefaultTextStyle.of(context).style.color
                      ?.withValues(alpha: GlassStyle.secondaryOpacity),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const new({required this.track});

  final Color track;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox.square(
        dimension: _ringSize,
        child: ProgressRing(fraction: 0, arc: track, track: track),
      ),
      const SizedBox(width: AppSpacing.m),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextPlaceholder(
            style: AppTypography.display,
            width: _numberPlaceholderWidth,
            color: track,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextPlaceholder(
            style: AppTypography.footnote,
            width: _captionPlaceholderWidth,
            color: track,
          ),
        ],
      ),
    ],
  );
}
