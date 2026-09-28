import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shlyakh/features/today/presentation/providers/sky_provider.dart';
import 'package:shlyakh/features/today/presentation/widgets/sky_background.dart';

/// Only the current sky: shown for the moment the journey start loads on
/// launch, before the router picks the access screen or Today.
class LaunchScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      SkyBackground(palette: ref.watch(skyProvider));
}
