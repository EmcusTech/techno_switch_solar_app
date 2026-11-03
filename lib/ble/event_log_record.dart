import 'package:Technoswitch/models/log_model.dart';
import 'package:Technoswitch/utils/constants/event_constants.dart';
import 'package:Technoswitch/utils/constants/event_log_texts.dart';
import 'package:Technoswitch/utils/timestamp_converter.dart';

/// Packed `data_t` event record (63 bytes, little-endian).
class EventLogRecordParser {
  const EventLogRecordParser._();

  static const int recordSize = 63;

  static List<LogModel> parsePayload(List<int> payload) {
    final List<LogModel> logs = <LogModel>[];
    for (
      var offset = 0;
      offset + recordSize <= payload.length;
      offset += recordSize
    ) {
      final int eventNo = _u32(payload, offset + 3);
      if (eventNo == 0) continue;
      logs.add(_toLog(payload, offset, eventNo));
    }
    return logs;
  }

  static LogModel _toLog(List<int> payload, int offset, int eventNo) {
    final int node = payload[offset];
    final int subNode = payload[offset + 1];
    final int module = payload[offset + 2];
    final int eventClass = payload[offset + 7];
    final int eventType = payload[offset + 9];
    final int eventStatus = payload[offset + 10];
    final int timestamp = _u32(payload, offset + 12);
    final String structText = _structText(payload, offset + 42);
    final String display = EventLogTexts.textFor(eventNo) ?? structText;
    final DateTime eventTime =
        timestamp == 0 ? DateTime.now() : _clockTime(timestamp);

    return LogModel(
      panelText: node == 0 ? '' : 'Panel No. $node',
      eventId: eventNo.toString(),
      eventDateTime: eventTime,
      panelNo: node.toString(),
      lBusNo: subNode.toString(),
      moduleNo: module.toString(),
      eventStatus: EventConstants.getEventStatusValue(eventStatus),
      eventClass: EventConstants.getEventClassValue(eventClass),
      eventSource: node == 0 ? '' : 'Panel No. $node',
      eventType: EventConstants.getEventType(eventType),
      eventSubType: display,
      text: display,
      isValid: timestamp != 0,
      retrievedAt: DateTime.now(),
    );
  }

  static DateTime _clockTime(int timestamp) {
    try {
      return TimestampConverter.clockTimeFromTimeStamp(timestamp);
    } catch (_) {
      return DateTime.now();
    }
  }

  static String _structText(List<int> payload, int offset) {
    final int end = offset + 21;
    if (end > payload.length) return '';
    final List<int> bytes = <int>[];
    for (var i = offset; i < end; i++) {
      final int byte = payload[i];
      if (byte == 0) break;
      if (byte >= 32 && byte < 127) bytes.add(byte);
    }
    return String.fromCharCodes(bytes);
  }

  static int _u32(List<int> bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }
}
