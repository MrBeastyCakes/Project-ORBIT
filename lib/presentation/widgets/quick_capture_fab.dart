import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/asteroid_provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/constants/orbit_constants.dart';

class QuickCaptureFab extends ConsumerStatefulWidget {
  const QuickCaptureFab({super.key});

  @override
  ConsumerState<QuickCaptureFab> createState() => _QuickCaptureFabState();
}

class _QuickCaptureFabState extends ConsumerState<QuickCaptureFab> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCaptureSheet() {
    _controller.clear();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ThemeConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final charCount = _controller.text.length;
            final remaining = OrbitConstants.asteroidMaxLength - charCount;
            final canCapture = _controller.text.trim().isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: ThemeConstants.starColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Quick Capture',
                        style: TextStyle(
                          color: ThemeConstants.starColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$remaining',
                        style: TextStyle(
                          color: remaining < 40
                              ? Colors.redAccent
                              : ThemeConstants.starColor.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLength: OrbitConstants.asteroidMaxLength,
                    maxLines: 4,
                    style: const TextStyle(color: ThemeConstants.starColor),
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Capture a thought…',
                      hintStyle: TextStyle(
                        color: ThemeConstants.starColor.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: ThemeConstants.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      counterText: '', // hide built-in counter; we show our own
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Capture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.accentColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          ThemeConstants.accentColor.withValues(alpha: 0.3),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: canCapture
                        ? () async {
                            final text = _controller.text.trim();
                            Navigator.of(ctx).pop();
                            await ref
                                .read(asteroidProvider.notifier)
                                .capture(text);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.auto_awesome,
                                          color: Colors.white, size: 16),
                                      SizedBox(width: 8),
                                      Text('Stardust captured'),
                                    ],
                                  ),
                                  backgroundColor: ThemeConstants.surfaceColor,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _showCaptureSheet,
      backgroundColor: ThemeConstants.accentColor,
      foregroundColor: Colors.white,
      tooltip: 'Quick Capture',
      child: const Icon(Icons.auto_awesome),
    );
  }
}
