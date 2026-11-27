import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Technoswitch/features/peripherals/panel_info/controllers/panel_info_controller.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/widgets/common/peripheral_sheet_chrome.dart';
import 'package:Technoswitch/widgets/common/peripheral_tab_bar.dart';

import 'package:Technoswitch/utils/constants/style_constants.dart';

class PanelInfoBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;
  final String? projectPanelName;
  final bool preferFactoryDefaults;

  const PanelInfoBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
    this.projectPanelName,
    this.preferFactoryDefaults = false,
  });

  @override
  State<PanelInfoBottomSheet> createState() => PanelInfoBottomSheetState();
}

class PanelInfoBottomSheetState extends State<PanelInfoBottomSheet>
    with SingleTickerProviderStateMixin {
  late final PanelInfoController controller;

  int _expandedTileCount = 0;
  TabController? _tabController;
  final FocusNode _panelNameFocusNode = FocusNode();
  final FocusNode _reminderFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (PeripheralSheetChrome.flat) {
      _tabController = TabController(length: 2, vsync: this);
    }
    _panelNameFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _reminderFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    controller = Get.put(
      PanelInfoController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
        projectPanelName: widget.projectPanelName,
        preferFactoryDefaults: widget.preferFactoryDefaults,
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _panelNameFocusNode.dispose();
    _reminderFocusNode.dispose();
    Get.delete<PanelInfoController>();
    super.dispose();
  }

  /// Kept for the create-project wizard, which commits each embedded sheet via
  /// its `GlobalKey`.
  Future<bool> commitLocal() => controller.commitLocal();

  Widget _scrollContent() {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle) {
          FocusScope.of(context).unfocus();
        }
        return false;
      },
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.embedInCreateFlow)
              _title(StringConstants.panelInformation),
            _panelInfoTile(),
            _eventReminderTile(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PanelInfoController>(
      init: controller,
      builder: (c) {
        final screenHeight = MediaQuery.of(context).size.height;

        if (widget.embedInCreateFlow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: _scrollContent())],
          );
        }

        final maxHeight =
            _expandedTileCount > 0 ? screenHeight * 0.80 : screenHeight * 0.50;

        return SafeArea(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: PeripheralSheetChrome.lipColor,
                  borderRadius: PeripheralSheetChrome.topRadius(),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: PeripheralSheetChrome.lipPadding,
                  ),
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: ColorConstants.white,
                      borderRadius: PeripheralSheetChrome.topRadius(),
                    ),
                    child: Stack(
                      children: [
                        const PeripheralSheetHeaderRow(),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 16,
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 16,
                          ),
                          child: Column(
                            children: [
                              _dragHandle(),
                              _title(StringConstants.panelInfo),
                              Expanded(
                                child:
                                    PeripheralSheetChrome.flat
                                        ? _panelInfoTabs()
                                        : _scrollContent(),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _downloadButton()),
                                  const SizedBox(width: 12),
                                  Expanded(child: _applyButton()),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────── TILES ─────────

  Widget _panelInfoTabs() {
    return Column(
      children: [
        PeripheralTabBar(
          controller: _tabController!,
          tabs: const [
            Tab(text: StringConstants.panelInfo),
            Tab(text: StringConstants.eventReminder),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _tabPage(_panelInfoFields()),
              _tabPage(_eventReminderFields()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabPage(Widget child) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle) {
          FocusScope.of(context).unfocus();
        }
        return false;
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: peripheralSheetScrollPadding(),
        child: child,
      ),
    );
  }

  Widget _panelInfoTile() {
    return _tileWrapper(
      title: StringConstants.panelInfo,
      children: [_panelInfoFields()],
    );
  }

  Widget _panelInfoFields() {
    return peripheralSheetFieldGrid([
      _textField(
        StringConstants.panelNo,
        controller.config.panelIdController,
        isNumeric: true,
        maxLength: 2,
        errorText: _panelNoOutOfRange ? StringConstants.panelNoRequired : null,
      ),
      _textField(
        StringConstants.panelName,
        controller.config.panelNameController,
        maxLength: 21,
        focusNode: _panelNameFocusNode,
        errorText:
            controller.config.panelNameController.text.trim().isEmpty
                ? StringConstants.panelNameRequired
                : null,
      ),
    ]);
  }

  /// Clock fields are still edited and applied here; bulk Config Log compare omits
  /// them so routine time drift does not mark Panel Info as mismatched.
  ///
  /// Temporarily hidden from the sheet. Restore by adding this tile back to
  /// [_scrollContent] and a matching tab in [_panelInfoTabs].
  // ignore: unused_element
  Widget _dateTimeTile() {
    return _tileWrapper(
      title: StringConstants.dateTime,
      children: [_dateTimeFields()],
    );
  }

  Widget _dateTimeFields() {
    return peripheralSheetFieldGrid([
      Row(
        children: [
          Expanded(
            child: Text(
              StringConstants.useMobileDateTime,
              style: StyleConstants.black16w600Style,
            ),
          ),
          Switch(
            value: controller.useMobileTime,
            onChanged: controller.toggleMobileTime,
          ),
        ],
      ),
      _numberField(
        StringConstants.year,
        controller.config.yearController,
        maxLength: 4,
      ),
      _numberField(
        StringConstants.month,
        controller.config.monthController,
        maxLength: 2,
      ),
      _numberField(
        StringConstants.day,
        controller.config.dayController,
        maxLength: 2,
      ),
      _numberField(
        StringConstants.hour,
        controller.config.hourController,
        maxLength: 2,
      ),
      _numberField(
        StringConstants.minute,
        controller.config.minuteController,
        maxLength: 2,
      ),
      _numberField(
        StringConstants.second,
        controller.config.secondController,
        maxLength: 2,
      ),
    ]);
  }

  Widget _eventReminderTile() {
    return _tileWrapper(
      title: StringConstants.eventReminder,
      children: [_eventReminderFields()],
    );
  }

  Widget _eventReminderFields() {
    return peripheralSheetFieldGrid([
      _numberField(
        StringConstants.delayS,
        controller.config.delayController,
        maxLength: 3,
        focusNode: _reminderFocusNode,
        errorText:
            _reminderOutOfRange
                ? StringConstants.eventReminderDelayMustBeBetween10And600Seconds
                : null,
      ),
    ]);
  }

  // ───────── TILE WRAPPER ─────────

  Widget _tileWrapper({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColorConstants.borderMuted),
        ),
        child: Theme(
          data: Theme.of(
            context,
          ).copyWith(dividerColor: ColorConstants.transparent),
          child: ExpansionTile(
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedTileCount += expanded ? 1 : -1;
              });
            },
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(title, style: StyleConstants.textDark15w600Style),
            children: [...children, const SizedBox(height: 14)],
          ),
        ),
      ),
    );
  }

  // ───────── INPUTS ─────────

  Widget _textField(
    String label,
    TextEditingController fieldController, {
    bool isNumeric = false,
    int? maxLength,
    FocusNode? focusNode,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: fieldController,
            focusNode: focusNode,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            maxLength: maxLength,
            buildCounter:
                maxLength == null
                    ? null
                    : (
                      BuildContext context, {
                      required int currentLength,
                      required bool isFocused,
                      required int? maxLength,
                    }) {
                      if (!isFocused) return null;
                      final max = maxLength ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$currentLength / $max',
                          style: StyleConstants.primary12w400Style.copyWith(
                            color:
                                currentLength == max
                                    ? ColorConstants.primary
                                    : Colors.grey,
                          ),
                        ),
                      );
                    },
            inputFormatters: [
              if (isNumeric) FilteringTextInputFormatter.digitsOnly,
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: (_) => controller.onFieldChanged(),
            decoration: _inputDecoration(errorText: errorText),
          ),
        ],
      ),
    );
  }

  bool get _panelNoOutOfRange {
    final panelNo = int.tryParse(controller.config.panelIdController.text);
    return panelNo == null || panelNo < 1 || panelNo > 31;
  }

  bool get _reminderOutOfRange {
    final delay = int.tryParse(controller.config.delayController.text);
    return delay == null || delay < 10 || delay > 600;
  }

  Widget _numberField(
    String label,
    TextEditingController fieldController, {
    int? maxLength,
    FocusNode? focusNode,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: fieldController,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: (_) => controller.onFieldChanged(),
            decoration: _inputDecoration(),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                errorText,
                style: StyleConstants.black12w500Style.copyWith(
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: StyleConstants.black13w600Style);
  }

  InputDecoration _inputDecoration({String? errorText}) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: ColorConstants.borderLight),
    );
    const focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: ColorConstants.primary, width: 2),
    );
    return InputDecoration(
      filled: true,
      isDense: true,
      fillColor: ColorConstants.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      errorText: errorText,
      errorMaxLines: 2,
      errorStyle: StyleConstants.black12w500Style.copyWith(
        color: Colors.orange,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      errorBorder: border,
      focusedErrorBorder: focusedBorder,
    );
  }

  // ───────── COMMON UI ─────────

  Widget _dragHandle() {
    return const PeripheralSheetDragHandle();
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text, style: StyleConstants.black20w700Style),
    );
  }

  Widget _downloadButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.primary,
          side: const BorderSide(color: ColorConstants.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          widget.onDownload();
        },
        child: Text(
          StringConstants.download,
          style: StyleConstants.primary16w600Style,
        ),
      ),
    );
  }

  Widget _applyButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed:
            controller.computeIsValid()
                ? () async {
                  if (await controller.commitLocal()) {
                    widget.onApply();
                  }
                }
                : null,
        child: Text(
          StringConstants.apply,
          style: StyleConstants.white14w600Style,
        ),
      ),
    );
  }
}
