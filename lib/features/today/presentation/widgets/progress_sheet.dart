import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shlyakh/app/router.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/app_radii.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/design/glass.dart';
import 'package:shlyakh/core/design/glass_panel.dart';
import 'package:shlyakh/core/l10n/format_extension.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/features/today/presentation/providers/today_view.dart';
import 'package:shlyakh/features/today/presentation/widgets/text_placeholder.dart';
import 'package:shlyakh/features/today/presentation/widgets/week_bars.dart';

/// Collapsed height as a fraction of the screen above the tab bar: it
/// shows the day's contribution and the current star. Expanded
/// fills the space it is given, which ends below the Today card.
const double _collapsedSize = 0.18;

/// Width of the loading placeholders, in logical pixels.
const double _placeholderWidth = 160;

/// The bottom sheet: the day's contribution and the current star;
/// expanded, today, the week and a link to Path.
class ProgressSheet extends StatelessWidget {
  const new({required this.view, required this.bottomClearance, super.key});

  /// Null while loading or on error (the card shows the error).
  final TodayView? view;

  /// Height at the bottom covered by the floating tab bar. The sheet runs
  /// under it to the screen edge; its collapsed height and its content are
  /// measured above it.
  final double bottomClearance;

  /// Height of the collapsed sheet on a screen [screenHeight] tall, from
  /// the bottom edge (it runs under the tab bar).
  static double collapsedHeight(double screenHeight, double bottomClearance) =>
      _collapsedSize * (screenHeight - bottomClearance) + bottomClearance;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).height;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final collapsed = collapsedHeight(screen, bottomClearance);
        // With very large text the card leaves less room than the
        // collapsed height: the sheet then cannot be dragged.
        return _sheet(context, collapsed: (collapsed / height).clamp(0.0, 1.0));
      },
    );
  }

  Widget _sheet(BuildContext context, {required double collapsed}) {
    final foreground = context.palette.onGlass;
    final track = foreground.withValues(alpha: GlassStyle.trackOpacity);
    return DraggableScrollableSheet(
      initialChildSize: collapsed,
      minChildSize: collapsed,
      snap: true,
      builder: (context, controller) => GlassPanel(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        child: _FadeAboveTabBar(
          clearance: bottomClearance,
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              AppSpacing.l + bottomClearance,
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
    final next = view.progress.next;
    final accent = context.palette.accent;
    return [
      Text(
        l10n.todayContribution(context.formatInt(view.xp)),
        style: AppTypography.title,
      ),
      const SizedBox(height: AppSpacing.xs),
      if (next == null)
        Text(l10n.routeComplete, style: AppTypography.footnote)
      else ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.bar),
          child: LinearProgressIndicator(
            value: next.xpIntoStar / next.xpForStar,
            minHeight: AppSpacing.xs,
            color: accent,
            backgroundColor: track,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.starFilled(l10n.percentValue(view.starPercent)),
          style: AppTypography.footnote,
        ),
        Text(
          l10n.xpToNextStar(
            context.formatInt(next.xpForStar - next.xpIntoStar),
          ),
          style: AppTypography.footnote,
        ),
      ],
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
          onTap: () => context.go(AppRoutes.path),
          child: Text(
            l10n.pathLink,
            style: AppTypography.headline.copyWith(color: accent),
          ),
        ),
      ),
    ];
  }
}

/// Fades [child] out where the floating tab bar starts, so only the glass
/// shows under and beside the bar, however far the sheet is dragged.
class _FadeAboveTabBar extends StatelessWidget {
  const new({required this.clearance, required this.child});

  final double clearance;
  final Widget child;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (bounds) {
      final height = bounds.height;
      final fadeStart = ((height - clearance) / height).clamp(0.0, 1.0);
      final fadeEnd = ((height - clearance + AppSpacing.s) / height).clamp(
        0.0,
        1.0,
      );
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        // Only alpha matters with dstIn: opaque keeps, transparent hides.
        colors: const [Colors.white, Colors.white, Colors.transparent],
        stops: [0, fadeStart, fadeEnd],
      ).createShader(bounds);
    },
    child: child,
  );
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
