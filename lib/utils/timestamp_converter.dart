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
  // Converts a timestamp from the device format to DateTime
  static DateTime clockTimeFromTimeStamp(int timestamp) {
    // Convert timestamp to ClockTime first
    ClockTime clockTime = _convertTimestampToClockTime(timestamp);
    
    // Convert ClockTime to DateTime
    return DateTime(
      clockTime.year,
      clockTime.month,
      clockTime.day,
      clockTime.hour,
      clockTime.minute,
      clockTime.second,
    );
  }

  // Internal method to convert timestamp to ClockTime structure
  static ClockTime _convertTimestampToClockTime(int timestamp) {
    // This is a simplified conversion - you may need to adjust based on the actual
    // timestamp format used by your device. The timestamp appears to be Unix-like.
    
    // Convert timestamp to DateTime first using standard Unix timestamp
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
    
    return ClockTime(
      year: dateTime.year,
      month: dateTime.month,
      day: dateTime.day,
      hour: dateTime.hour,
      minute: dateTime.minute,
      second: dateTime.second,
    );
  }

  // Alternative method if you have the specific device timestamp format
  static DateTime convertDeviceTimestamp(int timestamp) {
    // If the device uses a different epoch or format, adjust this calculation
    // For now, assuming it's similar to Unix timestamp
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true).toLocal();
  }

  // Utility method to format timestamp for display
  static String formatTimestamp(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }
} 