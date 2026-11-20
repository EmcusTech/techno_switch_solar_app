import 'package:flutter/foundation.dart';
import 'package:Technoswitch/models/new_event_log_progress.dart';

/// A running event-log download. [saved] finishes after the rows are stored,
/// or immediately when the download is not stored.
class EventLogRetrievalHandle {
  const EventLogRetrievalHandle({required this.progress, required this.saved});

  final ValueNotifier<NewEventLogProgress> progress;
  final Future<void> saved;
}
