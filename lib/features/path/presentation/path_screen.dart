import 'package:flutter/material.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';

/// The Path tab. A placeholder until its content is designed.
class PathScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Text(
          context.l10n.pathPlaceholder,
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
