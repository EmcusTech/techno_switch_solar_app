import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// A “rich UI” Date–Time picker that opens a bottom sheet with scroll wheels.
///
/// – Shows date, time, or both (via hideDate/hideTime).
/// – Uses CupertinoDatePicker inside a Material bottom sheet for a modern “wheel” UX.
/// – Renders a Card‐style button in-line instead of a plain TextFormField.
/// – Supports initial value, min/max dates, locale, custom labels, icons, and text style.
class RichDateTimePicker extends StatefulWidget {
  /// Initial date/time to display (defaults to now).
  final DateTime? initialDateTime;

  /// Earliest date selectable (ignored if hideDate is true).
  final DateTime? firstDate;

  /// Latest date selectable (ignored if hideDate is true).
  final DateTime? lastDate;

  /// If true, only the time wheel is shown.
  final bool hideDate;

  /// If true, only the date wheel is shown.
  final bool hideTime;

  /// Forces a specific locale on the pickers (optional).
  final Locale? locale;

  /// How to format the displayed date portion. Defaults to `yMd()`.
  final DateFormat? dateFormat;

  /// How to format the displayed time portion. Defaults to `jm()`.
  final DateFormat? timeFormat;

  /// Text to show when no value is selected (and initialDateTime is null).
  final String labelText;

  /// Icon to display on the left side of the button (optional).
  final Widget? icon;

  /// Text style for the displayed date/time.
  final TextStyle? textStyle;

  /// Whether the picker is enabled. If false, it renders “disabled” and ignores taps.
  final bool enabled;

  /// Called when the user picks a new DateTime.
  final ValueChanged<DateTime> onChanged;

  /// Creates a new [RichDateTimePicker].
  ///
  /// [onChanged] must not be null.
  /// If hideDate == false, [firstDate] and [lastDate] must not be null.
  const RichDateTimePicker({
    super.key,
    this.initialDateTime,
    this.firstDate,
    this.lastDate,
    this.hideDate = false,
    this.hideTime = false,
    this.locale,
    this.dateFormat,
    this.timeFormat,
    this.labelText = 'Select date & time',
    this.icon,
    this.textStyle,
    this.enabled = true,
    required this.onChanged,
  })  : assert(!(hideDate && hideTime), 'Cannot hide both date and time'),
        assert(
          hideDate || (firstDate != null && lastDate != null),
          'firstDate and lastDate are required if hideDate is false',
        );

  @override
  State<RichDateTimePicker> createState() => _RichDateTimePickerState();
}

class _RichDateTimePickerState extends State<RichDateTimePicker> {
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    // If the parent passed an initial value, use it; otherwise null.
    _selectedDateTime = widget.initialDateTime;
  }

  /// Returns the formatted string for the current selection, or the label if null.
  String get _displayText {
    if (_selectedDateTime == null) {
      return widget.labelText;
    }

    final df = widget.dateFormat ?? DateFormat.yMd();
    final tf = widget.timeFormat ?? DateFormat.jm();

    if (widget.hideDate) {
      return tf.format(_selectedDateTime!);
    } else if (widget.hideTime) {
      return df.format(_selectedDateTime!);
    } else {
      return '${df.format(_selectedDateTime!)} ${tf.format(_selectedDateTime!)}';
    }
  }

  /// Opens a ModalBottomSheet containing a CupertinoDatePicker (wheels).
  Future<void> _showBottomSheet(BuildContext context) async {
    if (!widget.enabled) return;

    // Start with either the existing selection or “now”:
    DateTime tempDateTime = _selectedDateTime ?? DateTime.now();

    // For date‐only mode: we need to remember the original time
    final int originalHour = tempDateTime.hour;
    final int originalMinute = tempDateTime.minute;

    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GestureDetector(
          // Dismiss when tapping outside
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(ctx).pop(),
          child: DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.25,
            maxChildSize: 0.7,
            builder: (_, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    // Header row with Cancel / Title / Confirm
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          Text(
                            widget.hideDate
                                ? 'Select Time'
                                : widget.hideTime
                                    ? 'Select Date'
                                    : 'Select Date & Time',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              // Finalize selection:
                              setState(() {
                                _selectedDateTime = tempDateTime;
                              });
                              widget.onChanged(tempDateTime);
                              Navigator.of(ctx).pop();
                            },
                            child: const Text(
                              'Confirm',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),
                    Expanded(
                      child: CupertinoTheme(
                        // Force the Cupertino wheels to match Material theme’s brightness
                        data: CupertinoThemeData(
                          brightness:
                              Theme.of(context).brightness, // light/dark
                        ),
                        child: _buildCupertinoPicker((DateTime newDt) {
                          // Update tempDateTime whenever the wheel moves:

                          if (widget.hideDate) {
                            // Time‐only mode: newDt keeps the original date from initialDateTime
                            tempDateTime = DateTime(
                              tempDateTime.year,
                              tempDateTime.month,
                              tempDateTime.day,
                              newDt.hour,
                              newDt.minute,
                            );
                          } else if (widget.hideTime) {
                            // Date‐only mode: keep originalHour/minute
                            tempDateTime = DateTime(
                              newDt.year,
                              newDt.month,
                              newDt.day,
                              originalHour,
                              originalMinute,
                            );
                          } else {
                            // DateAndTime mode: newDt has both fields
                            tempDateTime = newDt;
                          }
                        }),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Builds the appropriate CupertinoDatePicker based on hideDate/hideTime.
  Widget _buildCupertinoPicker(ValueChanged<DateTime> onChanged) {
    if (widget.hideDate) {
      // Time‐only wheel:
      return CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: _selectedDateTime ?? DateTime.now(),
        use24hFormat: false,
        minuteInterval: 1,
        onDateTimeChanged: onChanged,
        // Note: minimumDate/maximumDate are ignored in time mode.
      );
    } else if (widget.hideTime) {
      // Date‐only wheel:
      return CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: _selectedDateTime ?? DateTime.now(),
        minimumDate: widget.firstDate,
        maximumDate: widget.lastDate,
        onDateTimeChanged: onChanged,
      );
    } else {
      // Both date + time wheels:
      return CupertinoDatePicker(
        mode: CupertinoDatePickerMode.dateAndTime,
        initialDateTime: _selectedDateTime ?? DateTime.now(),
        minimumDate: widget.firstDate,
        maximumDate: widget.lastDate,
        onDateTimeChanged: onChanged,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = !widget.enabled;

    return Opacity(
      opacity: isDisabled ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: isDisabled ? null : () => _showBottomSheet(context),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    _displayText,
                    style: widget.textStyle ??
                        theme.textTheme.bodyMedium!.copyWith(
                          color: _selectedDateTime == null
                              ? Colors.grey[600]
                              : theme.textTheme.bodyMedium!.color,
                        ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: isDisabled
                      ? Colors.grey
                      : theme.iconTheme.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
