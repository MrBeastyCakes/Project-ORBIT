import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import '../../core/constants/theme_constants.dart';

class ZoomIndicator extends ConsumerWidget {
  const ZoomIndicator({super.key});

  String _labelForView(ViewLevel view) {
    return switch (view) {
      ViewLevel.galaxy => 'Galaxy',
      ViewLevel.system => 'System',
      ViewLevel.planet => 'Planet',
      ViewLevel.surface => 'Surface',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(navigationProvider).currentView;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ThemeConstants.surfaceColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ThemeConstants.accentColor.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        _labelForView(view),
        style: const TextStyle(
          color: ThemeConstants.starColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
