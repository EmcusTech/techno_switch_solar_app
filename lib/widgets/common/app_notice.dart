import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

/// Bumped when a Windows notice is shown or dismissed. The window frame listens.
final ValueNotifier<int> windowsNoticeRevision = ValueNotifier<int>(0);

/// Phone keeps a snackbar. Windows shows a short banner under the title bar.
void showAppNotice(
  BuildContext context, {
  required String message,
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 4),
}) {
  if (!context.mounted) return;
  if (Platform.isWindows) {
    _WindowsNoticeHost.show(message, accent: backgroundColor);
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration,
    ),
  );
}

class _WindowsNotice {
  _WindowsNotice({required this.message, required this.accent});

  final String message;
  final Color accent;
  Timer? timer;
}

class _WindowsNoticeHost {
  static final List<_WindowsNotice> _notices = [];

  static const Duration _visibleFor = Duration(seconds: 4);

  static void show(String message, {Color? accent}) {
    final notice = _WindowsNotice(
      message: message,
      accent: accent ?? ColorConstants.textBodyDark,
    );
    _notices.add(notice);
    while (_notices.length > 3) {
      final removed = _notices.removeAt(0);
      removed.timer?.cancel();
    }
    windowsNoticeRevision.value++;
    notice.timer = Timer(_visibleFor, () => dismiss(notice));
  }

  static void dismiss(_WindowsNotice notice) {
    notice.timer?.cancel();
    if (!_notices.remove(notice)) return;
    windowsNoticeRevision.value++;
  }
}

bool get hasWindowsNotices => _WindowsNoticeHost._notices.isNotEmpty;

/// The cards only. [WindowsAppFrame] positions this at the top right.
class WindowsNoticeLayer extends StatelessWidget {
  const WindowsNoticeLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final notices = _WindowsNoticeHost._notices.reversed.toList();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final notice in notices)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _WindowsNoticeCard(notice: notice),
            ),
        ],
      ),
    );
  }
}

class _WindowsNoticeCard extends StatelessWidget {
  const _WindowsNoticeCard({required this.notice});

  final _WindowsNotice notice;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorConstants.white,
      elevation: 6,
      shadowColor: ColorConstants.overlayBlack25,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _WindowsNoticeHost.dismiss(notice),
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: notice.accent,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Text(
                    notice.message,
                    style: StyleConstants.black14w500Style,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: IconButton(
                  onPressed: () => _WindowsNoticeHost.dismiss(notice),
                  icon: const Icon(Icons.close, size: 16),
                  color: ColorConstants.textSubtle,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
