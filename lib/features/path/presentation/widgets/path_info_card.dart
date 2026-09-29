import 'package:flutter/material.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/app_radii.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/design/glass.dart';
import 'package:shlyakh/core/design/glass_panel.dart';
import 'package:shlyakh/core/l10n/format_extension.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/features/path/domain/path_pages.dart';
import 'package:shlyakh/features/path/presentation/providers/path_view.dart';

/// Size of the icons on the card, in logical pixels.
const double _iconSize = 16;

/// The glass card under a constellation: XP to the next star, a bar and
/// the ETA on the current page; the "Completed" seal on a done page; a
/// lock and when it opens on the page ahead.
class PathInfoCard extends StatelessWidget {
  const new({required this.page, required this.view, super.key});

  /// Key of the seal's box.
  static const Key sealKey = Key('pathSeal');

  final PathPageView page;
  final PathView view;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final next = view.progress.next;
    final content = switch (page.state) {
      PageState.current when next != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.xpToNextStar(
              context.formatInt(next.xpForStar - next.xpIntoStar),
            ),
            style: AppTypography.headline,
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.bar),
            child: LinearProgressIndicator(
              value: next.xpIntoStar / next.xpForStar,
              minHeight: AppSpacing.xs,
              color: palette.accent,
              backgroundColor: palette.onGlass.withValues(
                alpha: GlassStyle.trackOpacity,
              ),
            ),
          ),
          if (view.etaDays case final days?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.pathEta(days), style: AppTypography.footnote),
          ],
        ],
      ),
      PageState.current => Text(
        l10n.routeComplete,
        style: AppTypography.headline,
      ),
      PageState.done when page.completedOn != null => Align(
        alignment: AlignmentDirectional.centerStart,
        child: DecoratedBox(
          key: sealKey,
          decoration: BoxDecoration(
            color: palette.seal,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  size: _iconSize,
                  color: palette.onSeal,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    l10n.pathSeal(context.formatDayMonth(_date(page))),
                    style: AppTypography.footnote.copyWith(
                      color: palette.onSeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      PageState.done => const SizedBox.shrink(),
      PageState.ahead => Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: _iconSize),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(l10n.pathOpensLater, style: AppTypography.footnote),
          ),
        ],
      ),
    };
    return GlassPanel(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: content,
      ),
    );
  }
}

DateTime _date(PathPageView page) {
  final d = page.completedOn!;
  return DateTime(d.year, d.month, d.day);
}
