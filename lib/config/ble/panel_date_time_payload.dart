/// Packed `st_panel_date_time_def`.
///
/// Hour, minute, second, date, and month are stored as written. Year is one
/// byte counting from [PanelDateTimePayload.yearBase], so 2026 is sent as 26.
abstract final class PanelDateTimePayload {
  static const int yearBase = 2000;

  static int encodeYear(int year) {
    final encoded = year - yearBase;
    if (encoded < 0) return 0;
    if (encoded > 255) return 255;
    return encoded;
  }

  static List<int> toBytes({
    required int hour,
    required int minute,
    required int second,
    required int day,
    required int month,
    required int year,
  }) {
    return <int>[
      hour & 0xFF,
      minute & 0xFF,
      second & 0xFF,
      day & 0xFF,
      month & 0xFF,
      encodeYear(year),
    ];
  }
}
