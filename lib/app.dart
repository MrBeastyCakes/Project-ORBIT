import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/theme_constants.dart';
import 'presentation/screens/galaxy_screen.dart';

class OrbitApp extends ConsumerWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Project ORBIT',
      theme: ThemeConstants.orbitDarkTheme,
      debugShowCheckedModeBanner: false,
      home: const GalaxyScreen(),
    );
  }
}
