import 'package:flutter/material.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/design/glass_panel.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';

/// The floating glass tab bar: Today, Path, History.
class FloatingTabBar extends StatelessWidget {
  const new({required this.index, required this.onSelect, super.key});

  /// Height of the bar, in logical pixels. Labels do not grow with the
  /// system text size, like the iOS tab bar.
  static const double height = 72;

  /// Space the bar and its inset take at the bottom of the screen; content
  /// that must stay visible ends above it.
  static double bottomClearance(BuildContext context) =>
      bottomInset(context) + height + AppSpacing.xs;

  /// Distance from the bottom of the screen to the bar.
  static double bottomInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + AppSpacing.m;

  /// The selected tab.
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final tabs = [
      (Icons.wb_sunny_outlined, l10n.tabToday),
      (Icons.route_outlined, l10n.tabPath),
      (Icons.history, l10n.tabHistory),
    ];
    final idle = palette.onGlass;
    return MediaQuery.withNoTextScaling(
      child: SizedBox(
        height: height,
        child: GlassPanel(
          shape: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, (icon, label)) in tabs.indexed)
                  _Tab(
                    icon: icon,
                    label: label,
                    selected: i == index,
                    color: i == index ? palette.accent : idle,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: AppSpacing.xxs),
              Text(label, style: AppTypography.caption.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
