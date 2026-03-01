import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../core/constants/theme_constants.dart';

class FormattingToolbar extends StatelessWidget {
  final QuillController controller;

  const FormattingToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ThemeConstants.surfaceColor,
        border: Border(
          top: BorderSide(
            color: ThemeConstants.accentColor,
            width: 0.5,
          ),
        ),
      ),
      child: QuillSimpleToolbar(
        controller: controller,
        config: const QuillSimpleToolbarConfig(
          showFontFamily: false,
          showFontSize: false,
          showBackgroundColorButton: false,
          showColorButton: false,
          showAlignmentButtons: false,
          showDirection: false,
          showDividers: false,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
          showClipboardCopy: false,
          showClipboardCut: false,
          showClipboardPaste: false,
          showSmallButton: false,
          showInlineCode: false,
          showCodeBlock: false,
          showQuote: false,
          showIndent: false,
          showLink: false,
          showRedo: true,
          showUndo: true,
        ),
      ),
    );
  }
}
