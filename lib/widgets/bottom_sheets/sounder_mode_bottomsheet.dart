import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';

class SounderModeBottomSheet extends StatefulWidget {
  final VoidCallback onDownload;
  final VoidCallback onApply;

  const SounderModeBottomSheet({
    super.key,
    required this.onDownload,
    required this.onApply,
  });

  @override
  State<SounderModeBottomSheet> createState() => _SounderModeBottomSheetState();
}

class _SounderModeBottomSheetState extends State<SounderModeBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController sounderBottomSheetController = ScrollController();

  final List<String> groupOptions = ['None', 'General', 'Zone', 'Ext. Out'];

  final Map<String, List<String>> functionOptionsMap = {
    'None': ['None'],
    'General': ['Fire Snd'],
    'Zone': ['Fire Snd'],
    'Ext. Out': ['Ext. Snd 1', 'Ext. Snd 2', 'Man. Release Snd'],
  };

  final List<String> yesNoOptions = ['No', 'Yes'];

  final List<String> typeOptions = ['Normal', 'IS (MTL5525)'];

  final List<String> actionOptions = [
    'Continuous',
    'Pulsing 1s on, 1s off',
    'Pulsing 1s on, 4s off',
    'Pulsing 2s on, 500ms off',
  ];

  final List<String> extOutActionOptions = [
    'Continuous',
    'Pulsing 1s on, 1s off',
    'Pulsing 1s on, 4s off',
    'Pulsing 2s on, 500ms off',
    'Off',
  ];

  late List<SounderConfig> sounders;

  final TextEditingController delayController = TextEditingController(
    text: '0',
  );

  String delayed = 'No';

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    sounders = List.generate(3, (i) {
      final config = SounderConfig(index: i);

      if (i == 0) {
        config.group = 'General';
        config.function = 'Fire Snd';
        config.groupLocked = true;
        config.functionLocked = true;
      }

      return config;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.90;

    return SafeArea(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              children: [
                _dragHandle(),
                _title('Sounder Mode Configuration'),

                // BODY
                Expanded(
                  child: NotificationListener<UserScrollNotification>(
                    onNotification: (notification) {
                      if (notification.direction != ScrollDirection.idle) {
                        FocusScope.of(context).unfocus();
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: sounderBottomSheetController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          ...List.generate(3, (i) => _sounderTile(i)),
                          const SizedBox(height: 24),
                          _advancedHeader(),
                          _advancedSection(),
                        ],
                      ),
                    ),
                  ),
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
        ),
      ),
    );
  }

  // ───────────────── SOUNDERS ─────────────────

  Widget _sounderTile(int index) {
    final sounder = sounders[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _sectionContainer(
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            'Sounder ${index + 1}',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          children: [
            _disabledField('Output', 'SNDR ${index + 1}'),

            _textField(
              label: 'Output Text',
              controller: sounder.outputController,
              maxLength: 21,
            ),

            if (!sounder.groupLocked)
              DropdownWidget(
                label: 'Group',
                value: sounder.group,
                items: groupOptions,
                onChanged: (v) {
                  setState(() {
                    sounder.group = v;
                    sounder.function = functionOptionsMap[v]!.first;
                  });
                },
              ),

            if (!sounder.functionLocked)
              DropdownWidget(
                label: 'Function',
                value: sounder.function,
                items: functionOptionsMap[sounder.group]!,
                onChanged: (v) => setState(() => sounder.function = v),
              ),

            if (sounder.group == 'Zone')
              _textField(
                label: 'Zone',
                controller: sounder.dynamicController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
              ),

            if (sounder.group == 'Ext. Out')
              _textField(
                label: 'Ext. Out',
                controller: sounder.dynamicController,
                enabled: false,
              ),

            if (sounder.group != 'Ext. Out')
              DropdownWidget(
                label: 'Enabled',
                value: sounder.enabled,
                items: yesNoOptions,
                onChanged: (v) => setState(() => sounder.enabled = v),
              ),

            DropdownWidget(
              label: 'Test',
              value: sounder.test,
              items: yesNoOptions,
              onChanged: (v) => setState(() => sounder.test = v),
            ),

            DropdownWidget(
              label: 'Type',
              value: sounder.type,
              items: typeOptions,
              onChanged: (v) => setState(() => sounder.type = v),
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  // ───────────────── ADVANCED ─────────────────

  Widget _advancedHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1.2),
        const SizedBox(height: 16),
        Text(
          'Advanced Configuration',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D3D3D),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _advancedSection() {
    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF8F8F8),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 2.5, color: Color(0xFFEC1D24)),
            ),
            labelColor: const Color(0xFFEC1D24),
            unselectedLabelColor: const Color(0xFF6E6E6E),
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'General'),
              Tab(text: 'Zone'),
              Tab(text: 'Ext Out'),
              Tab(text: 'Delay'),
            ],
            onTap: (_) {
              sounderBottomSheetController.animateTo(
                sounderBottomSheetController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 420,
          child: TabBarView(
            controller: _tabController,
            children: [_generalTab(), _zoneTab(), _extOutTab(), _delayTab()],
          ),
        ),
      ],
    );
  }

  Widget _generalTab() {
    return Column(
      children: [
        _disabledField('Function', 'Fire Snd'),
        DropdownWidget(
          label: 'Enabled',
          value: 'No',
          items: yesNoOptions,
          onChanged: (_) {},
        ),
        DropdownWidget(
          label: 'Test',
          value: 'No',
          items: yesNoOptions,
          onChanged: (_) {},
        ),
        DropdownWidget(
          label: 'Action',
          value: actionOptions.first,
          items: actionOptions,
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _zoneTab() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (_, i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _sectionContainer(
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                'Zone ${i + 1}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              children: [
                _disabledField('Function', 'Fire Snd'),
                _disabledField('Zone', '${i + 1}'),
                DropdownWidget(
                  label: 'Enabled',
                  value: 'No',
                  items: yesNoOptions,
                  onChanged: (_) {},
                ),
                DropdownWidget(
                  label: 'Test',
                  value: 'No',
                  items: yesNoOptions,
                  onChanged: (_) {},
                ),
                DropdownWidget(
                  label: 'Action',
                  value: actionOptions.first,
                  items: actionOptions,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _extOutTab() {
    final functions = ['Ext. Snd 1', 'Ext. Snd 2', 'Man. Release Snd'];

    return ListView.builder(
      itemCount: functions.length,
      itemBuilder: (_, i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _sectionContainer(
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                functions[i],
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              children: [
                _disabledField('Function', functions[i]),
                DropdownWidget(
                  label: 'Enabled',
                  value: 'No',
                  items: yesNoOptions,
                  onChanged: (_) {},
                ),
                DropdownWidget(
                  label: 'Test',
                  value: 'No',
                  items: yesNoOptions,
                  onChanged: (_) {},
                ),
                DropdownWidget(
                  label: 'Countdown',
                  value: extOutActionOptions.first,
                  items: extOutActionOptions,
                  onChanged: (_) {},
                ),
                DropdownWidget(
                  label: 'Hold',
                  value: extOutActionOptions.first,
                  items: extOutActionOptions,
                  onChanged: (_) {},
                ),
                DropdownWidget(
                  label: 'Release',
                  value: extOutActionOptions.first,
                  items: extOutActionOptions,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _delayTab() {
    return Column(
      children: [
        _textField(
          label: 'Delay (s)',
          controller: delayController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        DropdownWidget(
          label: 'Delayed',
          value: delayed,
          items: yesNoOptions,
          onChanged: (v) => setState(() => delayed = v),
        ),
      ],
    );
  }

  // ───────────────── UI HELPERS ─────────────────

  Widget _sectionContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCDCDC)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: child,
      ),
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

  Widget _textField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
            enabled: enabled,
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
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

  InputDecoration _inputDecoration({bool hasError = false}) {
    final borderColor =
        hasError ? const Color(0xFFEC1D24) : const Color(0xFFD0D0D0);

    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
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
        onPressed: widget.onDownload,
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
        onPressed: widget.onApply,
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

// ───────────────── MODEL ─────────────────

class SounderConfig {
  final int index;

  String group = 'None';
  String function = 'None';
  String enabled = 'No';
  String test = 'No';
  String type = 'Normal';

  bool groupLocked = false;
  bool functionLocked = false;

  TextEditingController outputController = TextEditingController();
  TextEditingController dynamicController = TextEditingController();

  SounderConfig({required this.index});
}
