import 'package:flutter/material.dart';

/// Tab area for a [TabBarView]. By default the area is as tall as the
/// tallest page. With [fitCurrentPage], it follows the open page so the
/// next section starts on the line below.
class SounderTabSlot extends StatefulWidget {
  const SounderTabSlot({
    super.key,
    required this.controller,
    required this.count,
    required this.pageBuilder,
    this.fitCurrentPage = false,
  });

  final TabController controller;
  final int count;
  final Widget Function(int index, bool forMeasure) pageBuilder;
  final bool fitCurrentPage;

  @override
  State<SounderTabSlot> createState() => _SounderTabSlotState();
}

class _SounderTabSlotState extends State<SounderTabSlot> {
  late List<double> _heights;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _heights = List<double>.filled(widget.count, 0);
    _index = widget.controller.index;
    widget.controller.addListener(_onTab);
  }

  @override
  void didUpdateWidget(covariant SounderTabSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTab);
      widget.controller.addListener(_onTab);
    }
    if (oldWidget.count != widget.count) {
      _heights = List<double>.filled(widget.count, 0);
    }
    _index = widget.controller.index;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (!widget.fitCurrentPage) return;
    final index = widget.controller.index;
    if (index == _index) return;
    setState(() => _index = index);
  }

  void _report(int index, Size size) {
    if (index < 0 || index >= _heights.length) return;
    if ((size.height - _heights[index]).abs() < 1) return;
    setState(() => _heights[index] = size.height);
  }

  double get _slotHeight {
    if (widget.fitCurrentPage) {
      final index = _index.clamp(0, _heights.length - 1);
      final height = _heights[index];
      return height <= 0 ? 1 : height;
    }
    var maxHeight = 0.0;
    for (final height in _heights) {
      if (height > maxHeight) maxHeight = height;
    }
    return maxHeight <= 0 ? 1 : maxHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        for (var i = 0; i < widget.count; i++)
          ExcludeFocus(
            child: IgnorePointer(
              child: Offstage(
                child: _TabPageMeasure(
                  onSize: (size) => _report(i, size),
                  child: widget.pageBuilder(i, true),
                ),
              ),
            ),
          ),
        SizedBox(
          height: _slotHeight,
          width: double.infinity,
          child: TabBarView(
            controller: widget.controller,
            children: [
              for (var i = 0; i < widget.count; i++)
                widget.pageBuilder(i, false),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabPageMeasure extends StatefulWidget {
  const _TabPageMeasure({required this.onSize, required this.child});

  final ValueChanged<Size> onSize;
  final Widget child;

  @override
  State<_TabPageMeasure> createState() => _TabPageMeasureState();
}

class _TabPageMeasureState extends State<_TabPageMeasure> {
  final GlobalKey _key = GlobalKey();
  Size? _last;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final size = box.size;
      if (size == _last) return;
      _last = size;
      widget.onSize(size);
    });
    return OverflowBox(
      alignment: Alignment.topCenter,
      minHeight: 0,
      maxHeight: double.infinity,
      child: KeyedSubtree(key: _key, child: widget.child),
    );
  }
}
