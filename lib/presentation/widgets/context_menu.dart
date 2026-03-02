import 'package:flutter/material.dart';

import '../../core/constants/theme_constants.dart';

enum CelestialBodyType { blackHole, star, planet, moon }

enum ContextMenuAction {
  // BlackHole
  addStar,
  // Star
  addPlanet,
  // Planet
  open,
  addMoon,
  createWormhole,
  // Moon
  toggleComplete,
  // Shared
  rename,
  changeColor,
  delete,
}

class ContextMenu extends StatelessWidget {
  final CelestialBodyType bodyType;
  final void Function(ContextMenuAction action) onAction;
  /// Current color of the body, shown as a swatch on the "Change Color" item.
  final int? currentColor;

  const ContextMenu({
    super.key,
    required this.bodyType,
    required this.onAction,
    this.currentColor,
  });

  List<_MenuEntry> get _entries {
    return switch (bodyType) {
      CelestialBodyType.blackHole => [
          _MenuEntry(ContextMenuAction.addStar, Icons.star_outline, 'Add Star'),
          _MenuEntry(ContextMenuAction.rename, Icons.edit_outlined, 'Rename'),
          _MenuEntry(
            ContextMenuAction.changeColor,
            Icons.palette_outlined,
            'Change Color',
          ),
          _MenuEntry(
            ContextMenuAction.delete,
            Icons.delete_outline,
            'Delete',
            isDestructive: true,
          ),
        ],
      CelestialBodyType.star => [
          _MenuEntry(
            ContextMenuAction.addPlanet,
            Icons.circle_outlined,
            'Add Planet',
          ),
          _MenuEntry(ContextMenuAction.rename, Icons.edit_outlined, 'Rename'),
          _MenuEntry(
            ContextMenuAction.changeColor,
            Icons.palette_outlined,
            'Change Color',
          ),
          _MenuEntry(
            ContextMenuAction.delete,
            Icons.delete_outline,
            'Delete',
            isDestructive: true,
          ),
        ],
      CelestialBodyType.planet => [
          _MenuEntry(
            ContextMenuAction.open,
            Icons.open_in_new,
            'Open',
          ),
          _MenuEntry(
            ContextMenuAction.addMoon,
            Icons.radio_button_unchecked,
            'Add Moon',
          ),
          _MenuEntry(
            ContextMenuAction.createWormhole,
            Icons.compare_arrows,
            'Create Wormhole',
            isDisabled: true,
          ),
          _MenuEntry(ContextMenuAction.rename, Icons.edit_outlined, 'Rename'),
          _MenuEntry(
            ContextMenuAction.changeColor,
            Icons.palette_outlined,
            'Change Color',
          ),
          _MenuEntry(
            ContextMenuAction.delete,
            Icons.delete_outline,
            'Delete',
            isDestructive: true,
          ),
        ],
      CelestialBodyType.moon => [
          _MenuEntry(
            ContextMenuAction.toggleComplete,
            Icons.check_circle_outline,
            'Toggle Complete',
          ),
          _MenuEntry(
            ContextMenuAction.delete,
            Icons.delete_outline,
            'Delete',
            isDestructive: true,
          ),
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeConstants.accentColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _entries.map((entry) {
            final isChangeColor =
                entry.action == ContextMenuAction.changeColor;
            final itemColor = entry.isDisabled
                ? Colors.white24
                : entry.isDestructive
                    ? Colors.redAccent
                    : ThemeConstants.starColor;
            return InkWell(
              onTap: entry.isDisabled ? null : () => onAction(entry.action),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (isChangeColor && currentColor != null && !entry.isDisabled)
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(currentColor!),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                      )
                    else
                      Icon(entry.icon, size: 18, color: itemColor),
                    const SizedBox(width: 10),
                    Text(
                      entry.label,
                      style: TextStyle(color: itemColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MenuEntry {
  final ContextMenuAction action;
  final IconData icon;
  final String label;
  final bool isDestructive;
  final bool isDisabled;

  const _MenuEntry(
    this.action,
    this.icon,
    this.label, {
    this.isDestructive = false,
    this.isDisabled = false,
  });
}
