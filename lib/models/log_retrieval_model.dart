class LogRetrievalModel {
  final int? id;
  final int siteId;
  final String sessionName;
  final int logCount;
  final DateTime retrievalDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  LogRetrievalModel({
    this.id,
    required this.siteId,
    required this.sessionName,
    required this.logCount,
    required this.retrievalDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from database map
  factory LogRetrievalModel.fromMap(Map<String, dynamic> map) {
    return LogRetrievalModel(
      id: map['id'] as int?,
      siteId: map['site_id'] as int,
      sessionName: map['session_name'] as String,
      logCount: map['log_count'] as int,
      retrievalDate: DateTime.fromMillisecondsSinceEpoch(
        map['retrieval_date'] as int,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'site_id': siteId,
      'session_name': sessionName,
      'log_count': logCount,
      'retrieval_date': retrievalDate.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create copy with modified fields
  LogRetrievalModel copyWith({
    int? id,
    int? siteId,
    String? sessionName,
    int? logCount,
    DateTime? retrievalDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LogRetrievalModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      sessionName: sessionName ?? this.sessionName,
      logCount: logCount ?? this.logCount,
      retrievalDate: retrievalDate ?? this.retrievalDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Generate session name based on site and timestamp
  static String generateSessionName(String siteName, DateTime retrievalDate) {
    final String sanitizedSiteName = siteName.replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '',
    );
    final String timestamp =
        '${retrievalDate.day.toString().padLeft(2, '0')}${retrievalDate.month.toString().padLeft(2, '0')}';
    return '${sanitizedSiteName}_${timestamp}_Log';
  }

  @override
  String toString() {
    return 'LogRetrievalModel{id: $id, siteId: $siteId, sessionName: $sessionName, logCount: $logCount, retrievalDate: $retrievalDate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogRetrievalModel &&
        other.id == id &&
        other.siteId == siteId &&
        other.sessionName == sessionName &&
        other.logCount == logCount &&
        other.retrievalDate == retrievalDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        siteId.hashCode ^
        sessionName.hashCode ^
        logCount.hashCode ^
        retrievalDate.hashCode;
  }
}
