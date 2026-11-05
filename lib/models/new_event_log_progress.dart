import 'package:Technoswitch/models/log_model.dart';

class NewEventLogProgress {
  const NewEventLogProgress({
    required this.percent,
    required this.logs,
    required this.done,
    this.noticeId = 0,
    this.notice,
  });

  final int percent;
  final List<LogModel> logs;
  final bool done;
  final int noticeId;
  final String? notice;

  static const NewEventLogProgress initial = NewEventLogProgress(
    percent: 0,
    logs: <LogModel>[],
    done: false,
  );
}
