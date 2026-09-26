import 'package:flutter/material.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';

class HomeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(context.l10n.appTitle)));
  }
}
