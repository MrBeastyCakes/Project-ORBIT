import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../core/constants/theme_constants.dart';

/// Space-themed preset colors for celestial bodies.
const List<Color> kSpacePresetColors = [
  Color(0xFF1A237E), // Deep Blue
  Color(0xFF0D47A1), // Ocean
  Color(0xFF00695C), // Teal
  Color(0xFF2E7D32), // Emerald
  Color(0xFFF9A825), // Gold
  Color(0xFFE65100), // Orange
  Color(0xFFB71C1C), // Ruby
  Color(0xFFAD1457), // Magenta
  Color(0xFF6A1B9A), // Purple
  Color(0xFF7E57C2), // Lavender
  Color(0xFFB3E5FC), // Ice
  Color(0xFFBDBDBD), // Silver
  Color(0xFFFF7043), // Coral
  Color(0xFF80CBC4), // Mint
  Color(0xFFFF6F00), // Sunset
  Color(0xFF311B92), // Cosmic
];

/// Shows the [ColorPickerDialog] and returns the selected color as an ARGB int,
/// or null if the user cancelled.
Future<int?> showColorPickerDialog(
  BuildContext context, {
  required int currentColor,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => ColorPickerDialog(currentColor: currentColor),
  );
}

class ColorPickerDialog extends StatefulWidget {
  final int currentColor;

  const ColorPickerDialog({super.key, required this.currentColor});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;
  bool _showCustomPicker = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = Color(widget.currentColor);
  }

  void _selectPreset(Color color) {
    setState(() {
      _selectedColor = color;
      _showCustomPicker = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeConstants.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Choose Color',
                style: TextStyle(
                  color: ThemeConstants.starColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Preview circle
              Center(
                child: _ColorPreview(color: _selectedColor),
              ),
              const SizedBox(height: 20),

              // Preset colors section
              Text(
                'PRESETS',
                style: TextStyle(
                  color: ThemeConstants.accentColor.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kSpacePresetColors.map((color) {
                  // ignore: deprecated_member_use
                  final isSelected = _selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () => _selectPreset(color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? ThemeConstants.accentColor
                              : Colors.white.withValues(alpha: 0.2),
                          width: isSelected ? 3 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Custom color toggle
              GestureDetector(
                onTap: () =>
                    setState(() => _showCustomPicker = !_showCustomPicker),
                child: Row(
                  children: [
                    Icon(
                      _showCustomPicker
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: ThemeConstants.accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Custom Color',
                      style: TextStyle(
                        color: ThemeConstants.accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (_showCustomPicker) ...[
                const SizedBox(height: 12),
                ColorPicker(
                  pickerColor: _selectedColor,
                  onColorChanged: (color) =>
                      setState(() => _selectedColor = color),
                  pickerAreaHeightPercent: 0.6,
                  enableAlpha: false,
                  displayThumbColor: true,
                  labelTypes: const [],
                  hexInputBar: true,
                ),
              ],

              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: ThemeConstants.starColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // ignore: deprecated_member_use
                      Navigator.of(context).pop(_selectedColor.value);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPreview extends StatelessWidget {
  final Color color;

  const _ColorPreview({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
    );
  }
}
