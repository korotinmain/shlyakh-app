import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shlyakh/app/router.dart';
import 'package:shlyakh/core/design/app_colors.dart';
import 'package:shlyakh/core/design/app_radii.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/design/glass.dart';
import 'package:shlyakh/core/design/glass_panel.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';
import 'package:shlyakh/core/l10n/format_extension.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/features/progress/domain/level_titles.dart';
import 'package:shlyakh/features/progress/presentation/providers/level_title.dart';
import 'package:shlyakh/features/today/presentation/providers/today_view.dart';
import 'package:shlyakh/features/today/presentation/widgets/text_placeholder.dart';
import 'package:shlyakh/features/today/presentation/widgets/week_bars.dart';

/// Sheet heights as fractions of the space above the tab bar: collapsed
/// shows the level, expanded the rest (spec, "ProgressSheet").
const double _collapsedSize = 0.18;
const double _expandedSize = 0.85;

/// Width of the loading placeholders, in logical pixels.
const double _placeholderWidth = 160;

/// The bottom sheet: level and title; expanded, today and the week.
class ProgressSheet extends StatelessWidget {
  const new({
    required this.view,
    required this.palette,
    required this.gender,
    super.key,
  });

  /// Null while loading or on error (the card shows the error).
  final TodayView? view;
  final SkyPalette palette;
  final GrammaticalGender gender;

  @override
  Widget build(BuildContext context) {
    final foreground = GlassStyle.onGlass(palette.surfaceTone);
    final track = foreground.withValues(alpha: GlassStyle.trackOpacity);
    return DraggableScrollableSheet(
      initialChildSize: _collapsedSize,
      minChildSize: _collapsedSize,
      maxChildSize: _expandedSize,
      snap: true,
      builder: (context, controller) => GlassPanel(
        tone: palette.surfaceTone,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.l,
          ),
          children: [
            Center(
              child: Container(
                width: AppSpacing.xl,
                height: AppSpacing.xxs,
                decoration: BoxDecoration(
                  color: track,
                  borderRadius: BorderRadius.circular(AppRadii.bar),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            if (view case final view?)
              ..._content(context, view, track, foreground)
            else
              TextPlaceholder(
                style: AppTypography.title,
                width: _placeholderWidth,
                color: track,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    TodayView view,
    Color track,
    Color foreground,
  ) {
    final l10n = context.l10n;
    final level = view.level;
    final accent = palette.accent.color;
    return [
      Text(
        l10n.levelLabel(level.level, levelChapter(l10n, level.level)),
        style: AppTypography.footnote,
      ),
      Text(levelTitle(l10n, level.level, gender), style: AppTypography.title),
      const SizedBox(height: AppSpacing.xs),
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.bar),
        child: LinearProgressIndicator(
          value: level.xpIntoLevel / level.xpForNextLevel,
          minHeight: AppSpacing.xs,
          color: accent,
          backgroundColor: track,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        l10n.xpToNextLevel(
          context.formatInt(level.xpForNextLevel - level.xpIntoLevel),
          level.level + 1,
        ),
        style: AppTypography.footnote,
      ),
      Text(
        l10n.xpRange(
          context.formatInt(view.levelStartXp),
          context.formatInt(view.nextLevelXp),
        ),
        style: AppTypography.footnote,
      ),
      const SizedBox(height: AppSpacing.l),
      Text(l10n.todayHeading, style: AppTypography.headline),
      const SizedBox(height: AppSpacing.xs),
      Wrap(
        spacing: AppSpacing.l,
        runSpacing: AppSpacing.xs,
        children: [
          _Stat(
            value: context.formatInt(view.steps),
            unit: l10n.stepsUnit(view.steps),
          ),
          _Stat(value: context.formatInt(view.xp), unit: l10n.xpUnit),
          Text(
            l10n.distanceApprox(context.formatKm(view.distanceMeters)),
            style: AppTypography.body,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.l),
      Text(l10n.weekHeading, style: AppTypography.headline),
      const SizedBox(height: AppSpacing.s),
      WeekBars(
        week: view.week,
        accent: accent,
        muted: foreground.withValues(alpha: GlassStyle.mutedOpacity),
      ),
      const SizedBox(height: AppSpacing.s),
      Text(
        l10n.weekTotal(view.weekSteps, context.formatInt(view.weekSteps)),
        style: AppTypography.footnote,
      ),
      const SizedBox(height: AppSpacing.l),
      Semantics(
        link: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go(AppRoutes.history),
          child: Text(
            l10n.historyLink,
            style: AppTypography.headline.copyWith(color: accent),
          ),
        ),
      ),
    ];
  }
}

class _Stat extends StatelessWidget {
  const new({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: value, style: tabular(AppTypography.headline)),
        TextSpan(text: ' $unit', style: AppTypography.body),
      ],
    ),
  );
}
