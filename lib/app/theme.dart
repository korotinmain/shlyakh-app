import 'package:flutter/material.dart';

// Placeholder seed until design tokens exist (roadmap stage 3).
const _seedColor = Color(0xFF3F6B4F);

ThemeData buildAppTheme() =>
    ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seedColor));
