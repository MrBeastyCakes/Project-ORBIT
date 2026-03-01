import 'package:flutter/material.dart';

import '../../core/constants/theme_constants.dart';

class BlackHoleLimitBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onUpgrade;

  const BlackHoleLimitBanner({
    super.key,
    required this.onDismiss,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: ThemeConstants.surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: const Text(
        'Upgrade to create more categories',
        style: TextStyle(color: ThemeConstants.starColor),
      ),
      leading: const Icon(
        Icons.workspace_premium,
        color: ThemeConstants.accentColor,
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text(
            'Dismiss',
            style: TextStyle(
              color: ThemeConstants.starColor.withValues(alpha: 0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: onUpgrade,
          child: const Text(
            'Upgrade',
            style: TextStyle(color: ThemeConstants.accentColor),
          ),
        ),
      ],
    );
  }
}
