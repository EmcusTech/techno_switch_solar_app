import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/widgets/windows/windows_app_menu.dart';
import 'package:window_manager/window_manager.dart';

class WindowsAppFrame extends StatefulWidget {
  const WindowsAppFrame({super.key, required this.child});

  final Widget child;

  @override
  State<WindowsAppFrame> createState() => _WindowsAppFrameState();
}

class _WindowsAppFrameState extends State<WindowsAppFrame> {
  late final OverlayEntry _frameEntry = OverlayEntry(builder: _buildFrame);

  @override
  void didUpdateWidget(WindowsAppFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _frameEntry.markNeedsBuild();
  }

  Widget _buildFrame(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [const WindowsAppMenuBar(), Expanded(child: widget.child)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_frameEntry]);
  }
}

class WindowsAppMenuBar extends StatefulWidget {
  const WindowsAppMenuBar({super.key});

  @override
  State<WindowsAppMenuBar> createState() => _WindowsAppMenuBarState();
}

class _WindowsAppMenuBarState extends State<WindowsAppMenuBar>
    with WindowListener {
  bool _maximized = true;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _syncMaximized() async {
    final maximized = await windowManager.isMaximized();
    if (!mounted || maximized == _maximized) return;
    setState(() => _maximized = maximized);
  }

  @override
  void onWindowMaximize() {
    if (!mounted) return;
    setState(() => _maximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (!mounted) return;
    setState(() => _maximized = false);
  }

  @override
  void onWindowRestore() {
    _syncMaximized();
  }

  Future<void> _toggleMaximized() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
      return;
    }
    await windowManager.maximize();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle itemStyle = ButtonStyle(
      foregroundColor: const WidgetStatePropertyAll(ColorConstants.black),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      visualDensity: VisualDensity.compact,
      alignment: Alignment.centerLeft,
    );
    final MenuStyle popupStyle = MenuStyle(
      backgroundColor: const WidgetStatePropertyAll(ColorConstants.white),
      surfaceTintColor: const WidgetStatePropertyAll(
        ColorConstants.transparent,
      ),
      elevation: const WidgetStatePropertyAll(2),
    );

    return Material(
      surfaceTintColor: ColorConstants.white,
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ColorConstants.white,
            border: const Border(
              bottom: BorderSide(color: ColorConstants.borderGray),
            ),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.white,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  // color: ColorConstants.primary,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 8,
                            ),
                            child: SvgPicture.asset(AssetConstants.logo),
                          ),
                          const IgnorePointer(
                            child: Text(
                              StringConstants.appTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: ColorConstants.black,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: DragToMoveArea(child: SizedBox.expand()),
                          ),
                          _CaptionButton(
                            icon: Icons.remove,
                            onPressed: () => windowManager.minimize(),
                          ),
                          _CaptionButton(
                            icon:
                                _maximized
                                    ? Icons.filter_none
                                    : Icons.crop_square,
                            onPressed: _toggleMaximized,
                          ),
                          _CaptionButton(
                            icon: Icons.close,
                            close: true,
                            onPressed: WindowsAppMenu.exitApp,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: ColorConstants.borderGray, height: 1),
                MenuBar(
                  style: const MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      ColorConstants.white,
                    ),
                    surfaceTintColor: WidgetStatePropertyAll(
                      ColorConstants.transparent,
                    ),
                    elevation: WidgetStatePropertyAll(0),
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 1),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  children: [
                    SizedBox(
                      width: 45,
                      child: SubmenuButton(
                        style: itemStyle,
                        menuStyle: popupStyle,
                        menuChildren: [
                          MenuItemButton(
                            style: itemStyle,
                            onPressed: WindowsAppMenu.openNewSite,
                            child: const Text(StringConstants.newSite),
                          ),
                          MenuItemButton(
                            style: itemStyle,
                            onPressed: WindowsAppMenu.exitApp,
                            child: const Text('Exit'),
                          ),
                        ],
                        child: const Text('File', maxLines: 1),
                      ),
                    ),
                    SizedBox(
                      width: 54,
                      child: SubmenuButton(
                        style: itemStyle,
                        menuStyle: popupStyle,
                        menuChildren: [
                          MenuItemButton(
                            style: itemStyle,
                            onPressed: WindowsAppMenu.openConnect,
                            child: const Text(StringConstants.connect),
                          ),
                          MenuItemButton(
                            style: itemStyle,
                            onPressed: WindowsAppMenu.openLiveEvents,
                            child: const Text(StringConstants.liveEvents),
                          ),
                          MenuItemButton(
                            style: itemStyle,
                            onPressed: WindowsAppMenu.openRetrieveLog,
                            child: const Text(StringConstants.retrieveLog),
                          ),
                        ],
                        child: const Text(StringConstants.panel, maxLines: 1),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: SubmenuButton(
                        style: itemStyle,
                        menuStyle: popupStyle,
                        menuChildren: [
                          MenuItemButton(
                            style: itemStyle,
                            onPressed: WindowsAppMenu.openSettings,
                            child: const Text(StringConstants.projectSettings),
                          ),
                        ],
                        child: const Text(StringConstants.setting, maxLines: 1),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: SubmenuButton(
                        style: itemStyle,
                        menuStyle: popupStyle,
                        menuChildren: [
                          MenuItemButton(
                            style: itemStyle,
                            onPressed: WindowsAppMenu.openHelp,
                            child: const Text(StringConstants.helpSupport),
                          ),
                        ],
                        child: const Text(StringConstants.help, maxLines: 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptionButton extends StatelessWidget {
  const _CaptionButton({
    required this.icon,
    required this.onPressed,
    this.close = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool close;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 40,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            final hovered =
                states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed);
            if (close && hovered) return ColorConstants.white;
            return ColorConstants.black;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (!states.contains(WidgetState.hovered) &&
                !states.contains(WidgetState.pressed)) {
              return ColorConstants.transparent;
            }
            if (!close) return ColorConstants.backgroundSubtle;
            return states.contains(WidgetState.pressed)
                ? const Color(0xFFC50F1F)
                : const Color(0xFFE81123);
          }),
        ),
        icon: Icon(icon, size: close ? 16 : 14),
      ),
    );
  }
}
