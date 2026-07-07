import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_type.dart';

enum ScanFlowMode { scanning, scanned }

class ScanFlowArgs {
  const ScanFlowArgs({
    required this.mode,
    this.isLiveEvent = false,
    this.isLiveEventLogs = false,
    this.createProjectExpectedPanelType,
    this.onCreateProjectPanelVerified,
    this.discoveredDevices = const [],
    this.scanType,
  });

  final ScanFlowMode mode;
  final bool isLiveEvent;
  final bool isLiveEventLogs;
  final String? createProjectExpectedPanelType;
  final VoidCallback? onCreateProjectPanelVerified;
  final List<dynamic> discoveredDevices;
  final ScanType? scanType;

  factory ScanFlowArgs.scanning({
    bool isLiveEvent = false,
    bool isLiveEventLogs = false,
    String? createProjectExpectedPanelType,
    VoidCallback? onCreateProjectPanelVerified,
  }) {
    return ScanFlowArgs(
      mode: ScanFlowMode.scanning,
      isLiveEvent: isLiveEvent,
      isLiveEventLogs: isLiveEventLogs,
      createProjectExpectedPanelType: createProjectExpectedPanelType,
      onCreateProjectPanelVerified: onCreateProjectPanelVerified,
    );
  }

  factory ScanFlowArgs.scanned({
    required List<dynamic> discoveredDevices,
    required ScanType scanType,
    bool isLiveEvent = false,
    bool isLiveEventLogs = false,
    String? createProjectExpectedPanelType,
    VoidCallback? onCreateProjectPanelVerified,
  }) {
    return ScanFlowArgs(
      mode: ScanFlowMode.scanned,
      isLiveEvent: isLiveEvent,
      isLiveEventLogs: isLiveEventLogs,
      createProjectExpectedPanelType: createProjectExpectedPanelType,
      onCreateProjectPanelVerified: onCreateProjectPanelVerified,
      discoveredDevices: discoveredDevices,
      scanType: scanType,
    );
  }

  ScanFlowArgs copyWith({
    ScanFlowMode? mode,
    bool? isLiveEvent,
    bool? isLiveEventLogs,
    String? createProjectExpectedPanelType,
    VoidCallback? onCreateProjectPanelVerified,
    List<dynamic>? discoveredDevices,
    ScanType? scanType,
  }) {
    return ScanFlowArgs(
      mode: mode ?? this.mode,
      isLiveEvent: isLiveEvent ?? this.isLiveEvent,
      isLiveEventLogs: isLiveEventLogs ?? this.isLiveEventLogs,
      createProjectExpectedPanelType:
          createProjectExpectedPanelType ?? this.createProjectExpectedPanelType,
      onCreateProjectPanelVerified:
          onCreateProjectPanelVerified ?? this.onCreateProjectPanelVerified,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      scanType: scanType ?? this.scanType,
    );
  }
}
