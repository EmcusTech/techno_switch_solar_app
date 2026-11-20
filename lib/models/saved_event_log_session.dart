class SavedEventLogSession {
  const SavedEventLogSession({
    required this.id,
    required this.panelId,
    required this.siteId,
    required this.retrievedAt,
    required this.logCount,
  });

  final int id;
  final String panelId;
  final int? siteId;
  final DateTime retrievedAt;
  final int logCount;

  factory SavedEventLogSession.fromMap(Map<String, dynamic> map) {
    final int millis = (map['retrieved_at'] as int?) ?? 0;
    return SavedEventLogSession(
      id: map['id'] as int,
      panelId: map['panel_id'] as String? ?? '',
      siteId: map['site_id'] as int?,
      retrievedAt: DateTime.fromMillisecondsSinceEpoch(millis),
      logCount: (map['log_count'] as int?) ?? 0,
    );
  }
}
