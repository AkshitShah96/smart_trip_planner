import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/splash_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SmartTripPlannerApp(),
    ),
  );
}

class SmartTripPlannerApp extends StatelessWidget {
  const SmartTripPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Trip Planner',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
