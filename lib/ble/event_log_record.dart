import 'package:Technoswitch/models/log_model.dart';
import 'package:Technoswitch/utils/constants/event_constants.dart';
import 'package:Technoswitch/utils/constants/event_log_texts.dart';

/// Packed `EventLog_t`, little-endian. `data_t` ends at [event_info_text],
/// then a 2-byte `u16_crc`. The timestamp is the 6-byte `st_date_time_t`.
class EventLogRecordParser {
  const EventLogRecordParser._();

  static const int eventNoOffset = 3;
  static const int timestampOffset = 12;
  static const int timestampLength = 6;
  static const int par0Offset = 31;
  static const int par1Offset = 32;
  static const int textOffset = 44;
  static const int textLength = 22;
  static const int crcOffset = textOffset + textLength;
  static const int crcLength = 2;
  static const int recordSize = crcOffset + crcLength;

  static List<LogModel> parsePayload(List<int> payload) {
    final List<LogModel> logs = <LogModel>[];
    for (
      var offset = 0;
      offset + recordSize <= payload.length;
      offset += recordSize
    ) {
      final int eventNo = _u32(payload, offset + eventNoOffset);
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
    final DateTime? eventTime = _clockTime(payload, offset + timestampOffset);
    final String configText = _structText(payload, offset + textOffset);
    final String display = EventLogTexts.textFor(eventNo) ?? '';

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
      configText: configText,
      par0: payload[offset + par0Offset],
      par1: payload[offset + par1Offset],
      isValid: eventTime != null,
      retrievedAt: DateTime.now(),
    );
  }

  static DateTime? _clockTime(List<int> payload, int offset) {
    if (offset + timestampLength > payload.length) return null;
    final int second = payload[offset];
    final int minute = payload[offset + 1];
    final int hour = payload[offset + 2];
    final int day = payload[offset + 3];
    final int month = payload[offset + 4];
    final int yearSince1900 = payload[offset + 5];
    if (second == 0 &&
        minute == 0 &&
        hour == 0 &&
        day == 0 &&
        month == 0 &&
        yearSince1900 == 0) {
      return null;
    }
    if (second > 59 ||
        minute > 59 ||
        hour > 23 ||
        day < 1 ||
        day > 31 ||
        month > 11) {
      return null;
    }
    final int year = 1900 + yearSince1900;
    final DateTime time = DateTime(year, month + 1, day, hour, minute, second);
    if (time.year != year ||
        time.month != month + 1 ||
        time.day != day ||
        time.hour != hour ||
        time.minute != minute ||
        time.second != second) {
      return null;
    }
    return time;
  }

  static String _structText(List<int> payload, int offset) {
    final int end = offset + textLength;
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
