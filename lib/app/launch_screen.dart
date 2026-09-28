import 'package:flutter/widgets.dart';
import 'package:shlyakh/features/today/presentation/widgets/sky_background.dart';

/// Only the sky: shown for the moment the journey start loads on launch,
/// before the router picks the access screen or Today.
class LaunchScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const SkyBackground();
}
