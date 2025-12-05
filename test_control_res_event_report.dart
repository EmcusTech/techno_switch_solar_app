import 'package:flutter/widgets.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_packet_generator.dart';

/// Test script to generate and display CONTROL_RES_EVENT_REPORT frame
///
/// To run this test, call: testControlResEventReportFrameGeneration()
/// from anywhere in your app, or use this as a standalone test.
void main() async {
  // Initialize Flutter bindings (required for Logger and platform channels)
  WidgetsFlutterBinding.ensureInitialized();

  // Call the test function to generate and display the frame
  await testControlResEventReportFrameGeneration(
    pktTxCnt: 1,
    pktRxCnt: 0,
    network: 5,
    node: 0,
    subnode: 0,
    module: 0,
    eventBufferMask: 3, // Radio event printer
    eventBufferMode: 0, // Start
  );
}
