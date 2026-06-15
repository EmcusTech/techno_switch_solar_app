class ClockTime {
  int year;
  int month;
  int day;
  int hour;
  int minute;
  int second;

  ClockTime({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
  });
}

class TimestampConverter {
  static DateTime clockTimeFromTimeStamp(int timestamp) {
    ClockTime clockTime = _convertTimestampToClockTime(timestamp);
    return DateTime(
      clockTime.year,
      clockTime.month,
      clockTime.day,
      clockTime.hour,
      clockTime.minute,
      clockTime.second,
    );
  }

  static ClockTime _convertTimestampToClockTime(int timestamp) {
    const int oneDayInSeconds = 86400;
    int adjustedTimestamp = timestamp - oneDayInSeconds;

    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
      adjustedTimestamp * 1000,
      isUtc: true,
    );

    return ClockTime(
      year: dateTime.year,
      month: dateTime.month,
      day: dateTime.day,
      hour: dateTime.hour,
      minute: dateTime.minute,
      second: dateTime.second,
    );
  }

  static DateTime convertDeviceTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    ).toLocal();
  }

  static String formatTimestamp(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }
}
