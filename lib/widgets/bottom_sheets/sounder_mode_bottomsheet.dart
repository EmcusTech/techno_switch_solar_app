import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    sounders = List.generate(3, (i) {
      final config = SounderConfig(index: i);

      // Sounder 1 locked as General - Fire Snd
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

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...List.generate(3, (i) => _sounderTile(i)),
                      const Divider(height: 32),
                      _advancedSection(),
                    ],
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
    );
  }

  // ─────────────────────────────
  // Sounder Tiles
  // ─────────────────────────────

  Widget _sounderTile(int index) {
    final sounder = sounders[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          'Sounder ${index + 1}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        children: [
          _outputField(sounder),
          _outputTextField(sounder),
          if (!sounder.groupLocked) _groupDropdown(sounder),
          if (!sounder.functionLocked) _functionDropdown(sounder),
          if (sounder.group == 'Zone') _zoneField(sounder),
          if (sounder.group == 'Ext. Out') _extOutField(sounder),
          if (sounder.group != 'Ext. Out') _enabledDropdown(sounder),
          _testDropdown(sounder),
          _typeDropdown(sounder),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _outputField(SounderConfig sounder) {
    return _disabledField('Output', 'SNDR ${sounder.index + 1}');
  }

  Widget _outputTextField(SounderConfig sounder) {
    return _textField('Output Text', sounder.outputController, maxLength: 21);
  }

  Widget _groupDropdown(SounderConfig sounder) {
    return DropdownWidget(
      label: 'Group',
      value: sounder.group,
      items: groupOptions,
      onChanged: (v) {
        setState(() {
          sounder.group = v;
          sounder.function = functionOptionsMap[v]!.first;
        });
      },
    );
  }

  Widget _functionDropdown(SounderConfig sounder) {
    return DropdownWidget(
      label: 'Function',
      value: sounder.function,
      items: functionOptionsMap[sounder.group]!,
      onChanged: (v) => setState(() => sounder.function = v),
    );
  }

  Widget _zoneField(SounderConfig sounder) {
    return _textField(
      'Zone',
      sounder.dynamicController,
      keyboardType: TextInputType.number,
    );
  }

  Widget _extOutField(SounderConfig sounder) {
    return _textField('Ext. Out', sounder.dynamicController, enabled: false);
  }

  Widget _enabledDropdown(SounderConfig sounder) {
    return DropdownWidget(
      label: 'Enabled',
      value: sounder.enabled,
      items: yesNoOptions,
      onChanged: (v) => setState(() => sounder.enabled = v),
    );
  }

  Widget _testDropdown(SounderConfig sounder) {
    return DropdownWidget(
      label: 'Test',
      value: sounder.test,
      items: yesNoOptions,
      onChanged: (v) => setState(() => sounder.test = v),
    );
  }

  Widget _typeDropdown(SounderConfig sounder) {
    return DropdownWidget(
      label: 'Type',
      value: sounder.type,
      items: typeOptions,
      onChanged: (v) => setState(() => sounder.type = v),
    );
  }

  // ─────────────────────────────
  // Advanced Section
  // ─────────────────────────────

  Widget _advancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Configuration',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 16),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Zone'),
            Tab(text: 'Ext Out'),
            Tab(text: 'Delay'),
          ],
        ),
        SizedBox(
          height: 400,
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
        return ExpansionTile(
          title: Text('Zone ${i + 1}'),
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
        );
      },
    );
  }

  Widget _extOutTab() {
    final functions = ['Ext. Snd 1', 'Ext. Snd 2', 'Man. Release Snd'];

    return ListView.builder(
      itemCount: functions.length,
      itemBuilder: (_, i) {
        return ExpansionTile(
          title: Text(functions[i]),
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
        );
      },
    );
  }

  Widget _delayTab() {
    return Column(
      children: [
        _textField(
          'Delay (s)',
          TextEditingController(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        DropdownWidget(
          label: 'Delayed',
          value: 'No',
          items: yesNoOptions,
          onChanged: (_) {},
        ),
      ],
    );
  }

  // ─────────────────────────────
  // UI Helpers
  // ─────────────────────────────

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
        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
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
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: enabled,
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            enabled: false,
            controller: TextEditingController(text: value),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadButton() {
    return OutlinedButton(
      onPressed: widget.onDownload,
      child: const Text('Download'),
    );
  }

  Widget _applyButton() {
    return ElevatedButton(
      onPressed: widget.onApply,
      child: const Text('Apply'),
    );
  }
}

// ─────────────────────────────
// Model
// ─────────────────────────────

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
