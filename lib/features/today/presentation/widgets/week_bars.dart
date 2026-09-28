import 'package:flutter/widgets.dart';
import 'package:shlyakh/core/design/app_radii.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/l10n/format_extension.dart';
import 'package:shlyakh/features/today/presentation/providers/today_view.dart';

/// Height of the tallest bar and of an empty day's bar, logical pixels.
const double _maxBarHeight = 64;
const double _minBarHeight = 4;

/// Seven bars, Monday to Sunday, relative to the week's best day.
class WeekBars extends StatelessWidget {
  const new({
    required this.week,
    required this.accent,
    required this.muted,
    super.key,
  });

  final List<WeekDay> week;
  final Color accent;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final best = week.fold(0, (m, d) => d.steps > m ? d.steps : m);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final day in week)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppSpacing.m,
                  height: best == 0
                      ? _minBarHeight
                      : _minBarHeight +
                            (_maxBarHeight - _minBarHeight) * day.steps / best,
                  decoration: BoxDecoration(
                    color: day.isToday ? accent : muted,
                    borderRadius: BorderRadius.circular(AppRadii.bar),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  context.formatShortWeekday(
                    DateTime(day.date.year, day.date.month, day.date.day),
                  ),
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
