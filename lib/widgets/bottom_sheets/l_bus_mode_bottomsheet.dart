import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/models/l_bus_setup_data_model.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';

class LBusBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const LBusBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<LBusBottomSheet> createState() => LBusBottomSheetState();
}

class LBusBottomSheetState extends State<LBusBottomSheet> {
  BleManager? manager;
  int selectedBus = 1;

  final List<String> yesNoOptions = ['No', 'Yes'];
  final List<String> productOptions = ['None', 'Rhino103R'];

  String enabled = 'No';
  String idLed = 'No';
  String product = 'None';

  final TextEditingController deviceTextController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController revisionController = TextEditingController();
  final TextEditingController productRevController = TextEditingController();
  final TextEditingController hardwareController = TextEditingController(
    text: '-',
  );
  final TextEditingController firmwareController = TextEditingController(
    text: '-',
  );
  final TextEditingController dateController = TextEditingController();
  final TextEditingController protocolController = TextEditingController();

  void _onListChanged() {
    _loadFromManager();
  }

  @override
  void initState() {
    super.initState();
    widget.refreshTrigger.addListener(_onRefreshTriggered);
    _loadData();
  }

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_onRefreshTriggered);
    manager?.lBusSetupDataList.removeListener(_onListChanged);
    deviceTextController.dispose();
    idController.dispose();
    revisionController.dispose();
    productRevController.dispose();
    hardwareController.dispose();
    firmwareController.dispose();
    dateController.dispose();
    protocolController.dispose();
    super.dispose();
  }

  void _onRefreshTriggered() {
    _loadFromManager();
  }

  Future<void> _loadData() async {
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
      manager?.lBusSetupDataList.addListener(_onListChanged);
    }
    if (manager?.isConnected == true) {
      _loadFromManager();
      return;
    }
    final cached = await PeripheralSetupCache.loadLBusSetup(widget.deviceId);
    if (cached != null && cached.isNotEmpty) {
      final list = cached.map((e) => LBusSetupData.fromJson(e)).toList();
      while (list.length < 31) {
        list.add(const LBusSetupData());
      }
      manager?.lBusSetupDataList.value = list;
    }
    _loadFromManager();
  }

  void _loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;

    final index = selectedBus - 1;
    if (index < 0 || index >= manager!.lBusSetupDataList.value.length) {
      return;
    }

    final data = manager!.lBusSetupDataList.value[index];

    if (mounted) {
      setState(() {
        enabled =
            yesNoOptions.contains(data.enabled)
                ? data.enabled
                : yesNoOptions.first;
        idLed =
            yesNoOptions.contains(data.idLed) ? data.idLed : yesNoOptions.first;
        product =
            productOptions.contains(data.product)
                ? data.product
                : productOptions.first;
        deviceTextController.text = data.deviceText;
        idController.text = data.id.toString();
        revisionController.text = data.revision.toString();
        productRevController.text = data.productRev;
        hardwareController.text = data.hardware.isEmpty ? '-' : data.hardware;
        firmwareController.text = data.firmware.isEmpty ? '-' : data.firmware;
        dateController.text = data.date;
        protocolController.text = data.protocol.toString();
      });
    }
  }

  bool _isValidLBus() {
    return deviceTextController.text.length <= 21;
  }

  void _saveCurrentBusToManager() {
    if (manager == null) return;
    final index = selectedBus - 1;
    if (index < 0 || index >= manager!.lBusSetupDataList.value.length) return;

    final existing = manager!.lBusSetupDataList.value[index];
    final updated = existing.copyWith(
      enabled: enabled,
      idLed: idLed,
      product: product,
      deviceText: deviceTextController.text,
      id: int.tryParse(idController.text) ?? existing.id,
      revision: int.tryParse(revisionController.text) ?? existing.revision,
      productRev: productRevController.text,
      hardware: hardwareController.text,
      firmware: firmwareController.text,
      date: dateController.text,
      protocol: int.tryParse(protocolController.text) ?? existing.protocol,
    );

    final list = List<LBusSetupData>.from(manager!.lBusSetupDataList.value);
    list[index] = updated;
    manager!.lBusSetupDataList.value = list;
  }

  Future<bool> commitLocal() async {
    if (manager == null || !_isValidLBus()) return false;
    FocusManager.instance.primaryFocus?.unfocus();
    _saveCurrentBusToManager();
    await PanelConfigCacheSync.saveLBus(
      manager!,
      widget.deviceId,
      widget.refreshTrigger,
    );
    return true;
  }

  Widget _scrollBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.embedInCreateFlow) _title('L-Bus Configuration'),
          _deviceSelector(),
          const SizedBox(height: 16),
          _sectionContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  _disabledField('L-Bus No', selectedBus.toString()),
                  DropdownWidget(
                    label: 'Enabled',
                    value: enabled,
                    items: yesNoOptions,
                    onChanged: (v) => setState(() => enabled = v),
                  ),
                  DropdownWidget(
                    label: 'ID LED',
                    value: idLed,
                    items: yesNoOptions,
                    onChanged: (v) => setState(() => idLed = v),
                  ),
                  DropdownWidget(
                    label: 'Product',
                    value: product,
                    items: productOptions,
                    onChanged: (v) => setState(() => product = v),
                  ),
                  _textField(
                    label: 'L-Bus Device Text',
                    controller: deviceTextController,
                    maxLength: 21,
                    onChanged: () => setState(() {}),
                  ),
                  _numericField(label: 'ID', controller: idController),
                  _numericField(
                    label: 'Revision',
                    controller: revisionController,
                  ),
                  _textField(
                    label: 'Product Rev.',
                    controller: productRevController,
                  ),
                  _readOnlyField('Hardware', hardwareController),
                  _readOnlyField('Firmware', firmwareController),
                  _textField(label: 'Date', controller: dateController),
                  _numericField(
                    label: 'Protocol',
                    controller: protocolController,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (widget.embedInCreateFlow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: _scrollBody())],
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.80),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE31C23),
            borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              ),
              // padding: EdgeInsets.only(
              //   left: 24,
              //   right: 24,
              //   top: 16,
              //   bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              // ),
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SvgPicture.asset('assets/svgs/bottomsheet_logo.svg'),
                      Padding(
                        padding: const EdgeInsets.only(right: 32.0),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                            child: const Icon(Icons.close, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      top: 16.0,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      children: [
                        _dragHandle(),
                        _title('L-Bus Mode'),
                        Expanded(child: _scrollBody()),
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
    );
  }

  Widget _deviceSelector() {
    return DropdownWidget(
      label: 'Select L-Bus',
      value: 'L-Bus $selectedBus',
      items: List.generate(31, (i) => 'L-Bus ${i + 1}'),
      dropdownListHeight: MediaQuery.sizeOf(context).height * 0.2,
      enableSearch: true,
      onChanged: (v) {
        final number = int.parse(v.split(' ').last);
        setState(() {
          _saveCurrentBusToManager();
          selectedBus = number;
          _loadFromManager();
        });
      },
    );
  }

  Widget _sectionContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCDCDC)),
      ),
      child: child,
    );
  }

  Widget _dragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF3D3D3D),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    int? maxLength,
    VoidCallback? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
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
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                currentLength == max
                                    ? const Color(0xFFEC1D24)
                                    : Colors.grey,
                          ),
                        ),
                      );
                    },
            inputFormatters: [
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: onChanged != null ? (_) => onChanged() : null,
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _numericField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _disabledField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            enabled: false,
            controller: TextEditingController(text: value),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: true,
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3D3D3D),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFEC1D24), width: 2),
      ),
    );
  }

  Widget _downloadButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEC1D24),
          side: const BorderSide(color: Color(0xFFEC1D24)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          widget.onDownload();
        },
        child: Text(
          'Download',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _applyButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC1D24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed:
            _isValidLBus()
                ? () async {
                  if (await commitLocal()) {
                    widget.onApply();
                  }
                }
                : null,
        child: Text(
          'Apply',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
