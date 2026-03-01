import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import '../providers/editor_provider.dart';
import '../providers/game_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/galaxy_provider.dart';
import '../widgets/formatting_toolbar.dart';
import '../../core/constants/theme_constants.dart';

class SurfaceScreen extends ConsumerStatefulWidget {
  final String planetId;

  const SurfaceScreen({super.key, required this.planetId});

  @override
  ConsumerState<SurfaceScreen> createState() => _SurfaceScreenState();
}

class _SurfaceScreenState extends ConsumerState<SurfaceScreen> {
  late QuillController _quillController;
  Timer? _debounce;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    _loadNote();
  }

  bool _loadError = false;

  Future<void> _loadNote() async {
    try {
      await ref.read(editorProvider.notifier).openNote(widget.planetId);
      if (!mounted) return;
      final editorState = ref.read(editorProvider);
      if (editorState.error != null) {
        if (mounted) setState(() => _loadError = true);
        return;
      }
      final content = editorState.content;
      if (content != null && content.deltaJson.isNotEmpty) {
        try {
          final deltaJson =
              jsonDecode(content.deltaJson) as List<dynamic>;
          final delta = Delta.fromJson(deltaJson);
          _quillController = QuillController(
            document: Document.fromDelta(delta),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (_) {
          _quillController = QuillController.basic();
        }
      }
      _quillController.addListener(_onDocumentChanged);
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
    }
  }

  void _onDocumentChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), _autoSave);
  }

  Future<void> _autoSave() async {
    final deltaJson =
        jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText();
    ref.read(editorProvider.notifier).updateContent(deltaJson, plainText);
    await ref.read(editorProvider.notifier).saveNote();
    if (!mounted) return;
    final error = ref.read(editorProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: ${error.message}'),
          backgroundColor: const Color(0xFF8B0000),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _autoSave,
          ),
        ),
      );
    }
  }

  Future<void> _onBack() async {
    _debounce?.cancel();
    await _autoSave();
    if (mounted) {
      // Restore camera to pre-surface position with smooth zoom-out.
      ref.read(gameProvider).cameraSystem.restorePreSurfaceState();
      ref.read(navigationProvider.notifier).exitSurface();
    }
  }

  String _planetName() {
    final planets = ref.read(galaxyProvider).planets;
    return planets
            .where((p) => p.id == widget.planetId)
            .firstOrNull
            ?.name ??
        'Note';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _quillController.removeListener(_onDocumentChanged);
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeConstants.surfaceColor,
        leading: BackButton(
          color: ThemeConstants.starColor,
          onPressed: _onBack,
        ),
        title: Text(
          _planetName(),
          style: const TextStyle(
            color: ThemeConstants.starColor,
            fontSize: 16,
          ),
        ),
        actions: [
          Consumer(
            builder: (_, ref, __) {
              final isDirty = ref.watch(editorProvider).isDirty;
              return isDirty
                  ? IconButton(
                      icon: const Icon(
                        Icons.save_outlined,
                        color: ThemeConstants.accentColor,
                      ),
                      tooltip: 'Save',
                      onPressed: () =>
                          ref.read(editorProvider.notifier).saveNote(),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: _loadError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFFF6B6B),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load note',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _loadError = false;
                        _initialized = false;
                      });
                      _loadNote();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.accentColor,
                    ),
                  ),
                ],
              ),
            )
          : !_initialized
          ? const Center(
              child: CircularProgressIndicator(
                color: ThemeConstants.accentColor,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: QuillEditor.basic(
                    controller: _quillController,
                    config: const QuillEditorConfig(
                      padding: EdgeInsets.all(16),
                      autoFocus: false,
                    ),
                  ),
                ),
                FormattingToolbar(controller: _quillController),
              ],
            ),
    );
  }
}
