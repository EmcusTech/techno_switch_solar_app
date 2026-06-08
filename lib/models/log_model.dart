class LogModel {
  final int? id;
  final int? siteId;
  final int? retrievalId;
  final String? panelText;
  final String? eventId;
  final DateTime? eventDateTime;
  final String? panelNo;
  final String? lBusNo;
  final String? moduleNo;
  final String? eventStatus;
  final String? eventClass;
  final String? eventSource;
  final String? eventType;
  final String? eventSubType;
  final String? identifier;
  final String? text;
  final DateTime? retrievedAt;
  final bool? isValid;

  LogModel({
    this.id,
    this.siteId,
    this.retrievalId,
    this.panelText,
    this.eventId,
    this.eventDateTime,
    this.panelNo,
    this.lBusNo,
    this.moduleNo,
    this.eventStatus,
    this.eventClass,
    this.eventSource,
    this.eventType,
    this.eventSubType,
    this.identifier,
    this.text,
    this.retrievedAt,
    this.isValid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'site_id': siteId,
      'retrieval_id': retrievalId,
      'panel_text': panelText,
      'event_id': eventId,
      'event_date_time': eventDateTime?.millisecondsSinceEpoch,
      'panel_no': panelNo,
      'l_bus_no': lBusNo,
      'module_no': moduleNo,
      'event_status': eventStatus,
      'event_class': eventClass,
      'event_source': eventSource,
      'event_type': eventType,
      'event_sub_type': eventSubType,
      'identifier': identifier,
      'text': text,
      'retrieved_at':
          retrievedAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'is_valid': isValid == null ? null : (isValid! ? 1 : 0),
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['id']?.toInt(),
      siteId: map['site_id']?.toInt(),
      retrievalId: map['retrieval_id']?.toInt(),
      panelText: map['panel_text'],
      eventId: map['event_id'],
      eventDateTime:
          map['event_date_time'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['event_date_time'])
              : null,
      panelNo: map['panel_no'],
      lBusNo: map['l_bus_no'],
      moduleNo: map['module_no'],
      eventStatus: map['event_status'],
      eventClass: map['event_class'],
      eventSource: map['event_source'],
      eventType: map['event_type'],
      eventSubType: map['event_sub_type'],
      identifier: map['identifier'],
      text: map['text'],
      retrievedAt:
          map['retrieved_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['retrieved_at'])
              : null,
      isValid: map['is_valid'] == null ? null : map['is_valid'] == 1,
    );
  }

  LogModel copyWith({
    int? id,
    int? siteId,
    int? retrievalId,
    String? panelText,
    String? eventId,
    DateTime? eventDateTime,
    String? panelNo,
    String? lBusNo,
    String? moduleNo,
    String? eventStatus,
    String? eventClass,
    String? eventSource,
    String? eventType,
    String? eventSubType,
    String? identifier,
    String? text,
    DateTime? retrievedAt,
    bool? isValid,
  }) {
    return LogModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      retrievalId: retrievalId ?? this.retrievalId,
      panelText: panelText ?? this.panelText,
      eventId: eventId ?? this.eventId,
      eventDateTime: eventDateTime ?? this.eventDateTime,
      panelNo: panelNo ?? this.panelNo,
      lBusNo: lBusNo ?? this.lBusNo,
      moduleNo: moduleNo ?? this.moduleNo,
      eventStatus: eventStatus ?? this.eventStatus,
      eventClass: eventClass ?? this.eventClass,
      eventSource: eventSource ?? this.eventSource,
      eventType: eventType ?? this.eventType,
      eventSubType: eventSubType ?? this.eventSubType,
      identifier: identifier ?? this.identifier,
      text: text ?? this.text,
      retrievedAt: retrievedAt ?? this.retrievedAt,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  String toString() {
    return 'LogModel{id: $id, siteId: $siteId, retrievalId: $retrievalId, panelText: $panelText, eventId: $eventId, eventDateTime: $eventDateTime, panelNo: $panelNo, lBusNo: $lBusNo, moduleNo: $moduleNo, eventStatus: $eventStatus, eventClass: $eventClass, eventSource: $eventSource, eventType: $eventType, eventSubType: $eventSubType, identifier: $identifier, text: $text, retrievedAt: $retrievedAt, isValid: $isValid}';
  }
}
