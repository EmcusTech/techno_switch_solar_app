import 'dart:io';

import 'package:flutter/material.dart';

/// Shared card size for dialogs shown while connecting on Windows.
const Size connectFlowDialogSize = Size(420, 370);

bool get connectFlowDialogIsFixedSize => Platform.isWindows;

/// Windows connect dialogs use one width and one height.
/// Phone dialogs stay capped at 420 wide and shrink to their content.
Widget connectFlowDialogFrame({required Widget child}) {
  if (!connectFlowDialogIsFixedSize) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: child,
    );
  }
  return SizedBox(
    width: connectFlowDialogSize.width,
    height: connectFlowDialogSize.height,
    child: child,
  );
}
