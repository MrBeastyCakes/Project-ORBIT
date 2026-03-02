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
      // Compute initial word count from loaded content
      final loadedText = _quillController.document.toPlainText().trim();
      _wordCount = loadedText.isEmpty
          ? 0
          : loadedText.split(RegExp(r'\s+')).length;
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
    }
  }

  int _wordCount = 0;

  void _onDocumentChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), _autoSave);
    // Update live word count
    final text = _quillController.document.toPlainText().trim();
    final count = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    if (count != _wordCount) {
      setState(() => _wordCount = count);
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _planetName(),
              style: const TextStyle(
                color: ThemeConstants.starColor,
                fontSize: 16,
              ),
            ),
            Text(
              '$_wordCount ${_wordCount == 1 ? 'word' : 'words'}',
              style: TextStyle(
                color: ThemeConstants.starColor.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (_, ref, __) {
              final editorState = ref.watch(editorProvider);
              if (editorState.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ThemeConstants.accentColor,
                    ),
                  ),
                );
              }
              if (editorState.isDirty) {
                return IconButton(
                  icon: const Icon(
                    Icons.save_outlined,
                    color: ThemeConstants.accentColor,
                  ),
                  tooltip: 'Save now',
                  onPressed: () =>
                      ref.read(editorProvider.notifier).saveNote(),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  Icons.cloud_done_outlined,
                  color: ThemeConstants.starColor.withValues(alpha: 0.4),
                  size: 20,
                ),
              );
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
