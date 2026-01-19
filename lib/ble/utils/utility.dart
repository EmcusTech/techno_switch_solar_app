import 'package:get/get.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_helper.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_transfer_manager.dart';
import 'package:techno_switch_solar_app/utils/encryption_utils.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';

Future<FrameData?> decryptTheDataPacketWithoutConversion(
  List<int> dataPacket,
) async {
  try {
    String hexString = bytesToHex(dataPacket);

    /// Decrypt received data
    List<int>? decryptedData = await EncryptionUtils().decryptData(hexString);

    // Get current state to determine step name
    final BleNotifyDataHandler handler = Get.find<BleNotifyDataHandler>();
    final BleStateMachine currentState = handler.currentBleState.value;

    // Determine step name based on current state
    String stepName = 'UNKNOWN';
    int stepNumber = 0;
    switch (currentState) {
      case BleStateMachine.reqEncryptionKey:
        stepName = 'RECEIVE ENCRYPTION KEY';
        stepNumber = 2;
        break;
      case BleStateMachine.sendingAuthMessage:
        stepName = 'RECEIVE AUTHENTICATION RESPONSE';
        stepNumber = 4;
        break;
      case BleStateMachine.requestingNetworkPacket:
        stepName = 'RECEIVE NETWORK PACKET RESPONSE';
        stepNumber = 6;
        break;
      case BleStateMachine.sendingPollPacket:
        stepName = 'RECEIVE POLL PACKET RESPONSE';
        stepNumber = 7;
        break;
      case BleStateMachine.sendingPasskeyPacket:
        stepName = 'PASSKEY PACKET SENT (response in poll packet)';
        stepNumber = 8;
        break;
      case BleStateMachine.sendingControlResEventReport:
        stepName = 'CONTROL_RES_EVENT_REPORT SENT (response in poll packet)';
        stepNumber = 9;
        break;
      case BleStateMachine.receivingEventLogs:
        stepName = 'RECEIVE EVENT LOG DATA';
        stepNumber = 10;
        break;
      case BleStateMachine.sendingDummyPacket:
        stepName = 'RECEIVE DUMMY PACKET RESPONSE';
        stepNumber = 10;
        break;
      default:
        stepName = 'RECEIVE DATA';
        stepNumber = 0;
    }

    Logger('========================================');
    Logger('TX/RX Logs - STEP $stepNumber: $stepName (RX)');
    Logger('========================================');
    Logger("TX/RX Logs - Current State: ${currentState.name}");

    // Log non-encrypted RX data (after decryption)
    String rxHex = decryptedData!
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(' ');
    String rxAscii = _bytesToAscii(decryptedData);
    Logger(
      'TX/RX Logs - Non-encrypted RX Data (${decryptedData.length} bytes):',
    );
    Logger('TX/RX Logs - Hex: $rxHex');
    Logger('TX/RX Logs - ASCII: $rxAscii');

    // Parse frame to get command and frame type
    FrameData parsedFrame = DataTransferManager().parseRxFrame(decryptedData);

    if (parsedFrame.commandByte.isNotEmpty &&
        parsedFrame.commandByte.length >= 2) {
      int cmdValue =
          (int.parse(parsedFrame.commandByte[0], radix: 16) << 8) |
          int.parse(parsedFrame.commandByte[1], radix: 16);
      Logger(
        'TX/RX Logs - Command: 0x${cmdValue.toRadixString(16).padLeft(4, '0')}',
      );
    }
    Logger('TX/RX Logs - Frame Type: ${parsedFrame.frameTypeByte}');
    Logger(
      'TX/RX Logs - Payload Length: ${parsedFrame.payloadData.length} bytes',
    );
    Logger('TX/RX Logs - ========================================\n');

    return parsedFrame;
  } catch (e) {
    Logger('TX/RX Logs - ERROR: Failed to decrypt/parse frame: $e');
    // TODO(username): message.
    return null;
  }
}

String _bytesToAscii(List<int> bytes) {
  return bytes.map((b) {
    if (b >= 32 && b <= 126) {
      // Printable ASCII characters
      return String.fromCharCode(b);
    } else {
      // Non-printable characters shown as dots
      return '.';
    }
  }).join();
}
