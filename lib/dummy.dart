import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/widgets/common/common_numeric_keypad_widget.dart';

class Dummy extends StatefulWidget {
  const Dummy({super.key});

  @override
  State<Dummy> createState() => _DummyState();
}

class _DummyState extends State<Dummy> {
  void showNumerickeypadBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => CommonNumericKeypadWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showNumerickeypadBottomSheet();
          },
          child: Text("Tap", style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
