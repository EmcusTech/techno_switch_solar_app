import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/widgets/windows/windows_app_menu.dart';

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

class WindowsAppMenuBar extends StatelessWidget {
  const WindowsAppMenuBar({super.key});

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

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ColorConstants.backgroundSubtle,
        border: Border(bottom: BorderSide(color: ColorConstants.borderGray)),
      ),
      child: MenuBar(
        style: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(ColorConstants.white),
          surfaceTintColor: WidgetStatePropertyAll(ColorConstants.transparent),
          elevation: WidgetStatePropertyAll(0),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
          visualDensity: VisualDensity.compact,
        ),
        children: [
          SubmenuButton(
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
            child: const Text('File'),
          ),
          SubmenuButton(
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
            child: const Text(StringConstants.panel),
          ),
          SubmenuButton(
            style: itemStyle,
            menuStyle: popupStyle,
            menuChildren: [
              MenuItemButton(
                style: itemStyle,
                onPressed: WindowsAppMenu.openSettings,
                child: const Text(StringConstants.projectSettings),
              ),
            ],
            child: const Text(StringConstants.settings),
          ),
          SubmenuButton(
            style: itemStyle,
            menuStyle: popupStyle,
            menuChildren: [
              MenuItemButton(
                style: itemStyle,
                onPressed: WindowsAppMenu.openHelp,
                child: const Text(StringConstants.helpSupport),
              ),
            ],
            child: const Text(StringConstants.help),
          ),
        ],
      ),
    );
  }
}
