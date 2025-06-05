class EventConstants {
  // Event types
  static const int evtTypeAllSearchNoneRsp = 0;
  static const int evtTypeGeneral = 1;
  static const int evtTypeAction = 2;
  static const int evtTypeRestart = 3;
  static const int evtTypeNetworkAddress = 4;
  static const int evtTypeAccess = 5;
  static const int evtTypeZone = 6;
  static const int evtTypeArea = 7;
  static const int evtTypeInput = 8;
  static const int evtTypeOutput = 9;
  static const int evtTypeSupervisedInput = 10;
  static const int evtTypeSupervisedOutput = 11;
  static const int evtTypeZoneInput = 12;
  static const int evtTypeSupervisory = 13;
  static const int evtTypeGeneralEquipment = 14;
  static const int evtTypeExtZone = 15;
  static const int evtTypeZoneEquipment = 16;
  static const int evtTypeAreaEquipment = 17;
  static const int evtTypeExtZoneEquipment = 18;
  static const int evtTypeTimerAlarm = 19;
  static const int evtTypeServiceDue = 20;
  static const int evtTypeSupply = 21;
  static const int evtTypeNetwork = 22;

  static final Map<int, String> supervisoryFaultParam12Name = {
    2: "Open",
    3: "Short",
    4: "Double EOL",
    5: "Low resistance",
    7: "Overload"
  };

  static final Map<int, String> eventParam0NumberNameList = {
    6: "Zone no.{par0}",
    10: "Input no.{par0}",
    11: "Output no.{par0}",
    12: "Input no.{par0}",
    15: "Ext. zone no.{par0}",
  };

  static final Map<int, String> eventParam1NumberNameList = {
    16: "Zone no.{par1}",
    17: "Area no.{par1}",
    18: "Ext zone no.{par1}",
  };

  static final List<String> statusEventTypeDescriptions = [
    "All (search), None (response)",
    "General",
    "Action",
    "Restart",
    "Network Address",
    "Access",
    "Zone",
    "Area",
    "Input",
    "Output",
    "Supervised Input",
    "Supervised Output",
    "Zone Input",
    "Supervisory",
    "General equipment",
    "Ext. zone",
    "Zone equipment",
    "Area equipment",
    "Ext. zone equipment",
    "Timer alarm",
    "Service due",
    "Supply",
    "Network"
  ];

  static final List<String> statusEventClassNames = [
    "All(search),None(Response)",
    "Release",
    "Alarm",
    "Fault",
    "Disablement",
    "Condition",
    "Action",
    "Evacuation",
  ];

  static final List<String> statusEventStatusValue = [
    "All(search),Passive(Response)",
    "Active",
    "Accepted",
    "Logged"
  ];

  static final List<List<String>> eventDescriptions = [
    // 0 - None
    ["-"],

    // 1 - General
    [
      "Memory lock open",
      "Service switch open",
      "Tamper switch open",
      "Key-lock open",
      "Non-volatile memory changed",
      "Configuration changed",
      "External fault",
      "External alarm 1",
      "Configuration defaulted",
      "Vaux overload",
      "External alarm 2",
      "Evacuation",
      "External Supervisory on",
      "External supply fault",
      "Sounders disabled",
      "Event buffer cleared",
      "Non-volatile text changed",
      "Firmware changed",
      "Firmware check-sum error"
    ],

    // 2 - Action
    [
      "Memory lock closed",
      "Service switch closed",
      "Tamper switch closed",
      "Key-lock closed",
      "Reset",
      "Time changed",
      "Time defaulted",
      "Controls enabled",
      "Controls disabled",
      "Silence buzzer",
      "Silence sounders",
      "Activate sounders",
      "N/A",
      "External fault ok",
      "External controls disabled",
      "Vaux ok",
      "External Supervisory off",
      "External controls enabled",
      "External supply fault ok",
      "Sounders enabled",
      "Sounder delays enabled",
      "Sounder delays disabled",
      "External reset",
      "External silence buzzer",
      "External silence sounders",
      "External activate sounders",
      "I/O suspended",
      "Local Controls enabled",
      "Local Controls disabled"
    ],

    // 3 - Restart
    ["-"],

    // 4 - Network
    [
      "Network communication down",
      "Network communication up",
      "Invalid Product Type",
      "No Permission",
      "Invalid Hardware Version (Major & Minor)",
      "Invalid Product Option",
      "Invalid Product Version",
      "Invalid Software Build",
      "Invalid Software Version (Major & Minor)",
      "Invalid Software Release",
      "Invalid Software Date",
      "Invalid Software Protocol",
      "Invalid Product Revision",
      "Silence Buzzer",
      "Tamper on",
      "Tamper off",
      "Local controls enabled",
      "Local controls disabled",
      "Double address",
      "Extnl controls enabled",
      "Extnl controls disabled"
    ],

    // 5 - Access
    ["Enabled", "Violation", "Disabled"],

    // 6 - Zone
    [
      "Enabled",
      "Disabled",
      "Test On",
      "Test Off",
      "Alarm (Auto)",
      "Fault",
      "Supervisory fault",
      "Supervisory normal",
      "Test-alarm on",
      "Test-alarm off",
      "Alarm off (Auto)",
      "Alarm (MCP)",
      "Alarm off (MCP)",
      "Evacuation"
    ],

    // 7 - Area
    [
      "Enabled",
      "Disabled",
      "Test On",
      "Test Off",
      "Alarm",
      "Fault",
      "Coincidence",
      "Test-alarm on",
      "Test-alarm off",
      "Test-coincidence on",
      "Test-coincidence off",
      "Evacuation"
    ],

    // 8 - Input
    [
      "Enabled",
      "Disabled",
      "Test On",
      "Test Off",
      "Input on (test)",
      "Input off (test)",
      "Input duplication"
    ],

    // 9 - Output
    ["Enabled", "Disabled", "Test On", "Test Off"],

    // 10 - Supervised Input
    ["Supervisory fault", "Supervisory normal"],

    // 11 - Supervised Output
    ["Supervisory fault", "Supervisory normal"],

    // 12 - Zone Input
    ["Supervisory fault", "Supervisory normal"],

    // 13 - Supervisory
    ["Process limit", "Mailbox limit", "Queue limit"],

    // 14 - General Equipment
    [
      "Enabled",
      "Disabled",
      "Test On",
      "Test Off",
      "Fault",
      "Normal",
      "Delay enabled",
      "Delay disabled"
    ],

    // 15 - Ext. Zone
    [
      "Enabled",
      "Disabled",
      "Test On",
      "Test Off",
      "Fault On",
      "Fault Off",
      "Automatic mode",
      "Manual mode",
      "Manual release initiated",
      "Automatic release initiated",
      "Extinguishant released",
      "Release aborted",
      "Hold on",
      "Hold off",
      "Release end",
      "Extinguishing reset blocked",
      "Extinguishing reset allowed",
      "Abort on",
      "Abort off",
      "Pressure monitor low",
      "Pressure monitor normal",
      "Valve monitoring on",
      "Valve monitoring off",
      "Release count down restarted",
      "Release count down suspended",
      "Release count down continued",
      "Release count down terminated",
      "Extinguishant release start",
      "Actuator undefined",
      "Actuator defined",
      "Manual test-release on",
      "Manual test-release off",
      "Automatic test-release on",
      "Automatic test-release off",
      "Timed Extraction start",
      "Timed Extraction end",
      "Manual Extraction start",
      "Manual Extraction end",
      "External gas disable on",
      "External gas disable off",
      "External supervisory on",
      "External supervisory off",
      "MCP alarm",
      "Extn1 MCP alarm",
      "Valve fault on",
      "Valve fault off",
      "Start delayed extraction",
      "External extinguishing fault on",
      "External extinguishing fault off",
      "Hold fault on",
      "Hold fault off",
      "Auto/Manual fault on",
      "Auto/Manual fault off",
      "Hold disabled",
      "Hold enabled",
      "Extnl Manual Trigger Fault on",
      "Extnl Manual Trigger Fault off",
      "Extnl Gas Disable Fault on",
      "Extnl Gas Disable Fault off",
      "Extnl Extinguishing Flt Fault on",
      "Extnl Extinguishing Flt Fault off"
    ],

    // 16 - Zone Equipment
    [
      "Enabled",
      "Disabled",
      "Test On",
      "Test Off",
      "Fault",
      "Normal",
      "Delay enabled",
      "Delay disabled"
    ],

    // 17 - Area Equipment
    [
      "Enabled",
      "Disabled",
      "Test On",
      "Test Off",
      "Fault",
      "Normal",
      "Delay enabled",
      "Delay disabled"
    ],

    // 18 - Ext. Zone Equipment
    [
      "Enabled",
      "Disabled",
      "Test On",
      "Test Off",
      "Fault",
      "Normal",
      "Delay enabled",
      "Delay disabled"
    ],

    // 19 - Timer alarm
    ["Alarm on", "Alarm off"],

    // 20 - Service due
    ["Service due"],

    // 21 - Supply
    [
      "Earth fault ok",
      "Earth fault high",
      "Earth fault low",
      "Vin voltage ok",
      "Vin voltage high",
      "Vin voltage low",
      "Vout voltage ok",
      "Vout voltage high",
      "Vout voltage low",
      "Mains ok",
      "Mains fault",
      "Battery voltage ok",
      "Battery voltage high",
      "Battery voltage low",
      "Battery low warning",
      "Battery shut-off",
      "Battery disconnected",
      "Battery connected",
      "Charger fault",
      "Charger ok",
      "Booster fault",
      "Booster ok",
      "Battery test fault",
      "Battery test ok",
      "Supply fault",
      "Supply fault ok",
      "Extnl fault",
      "Extnl fault ok"
    ],

    // 22 - Network
    ["Ring open", "Ring closed", "Ring disconnect", "Test on", "Test off"]
  ];

  static String getEventStatusValue(int evtStatus) {
    try {
      return statusEventStatusValue[evtStatus];
    } catch (e) {
      return "UNKNOWN_STATUS";
    }
  }

  static String getEventClassValue(int evtClass) {
    try {
      return statusEventClassNames[evtClass];
    } catch (e) {
      return "UNKNOWN_CLASS";
    }
  }

  static String getEventType(int evtType) {
    try {
      return statusEventTypeDescriptions[evtType];
    } catch (e) {
      return "UNKNOWN_TYPE";
    }
  }

  static String getEventDescription(int eventType, int eventSubtype) {
    try {
      return eventDescriptions[eventType][eventSubtype];
    } catch (e) {
      return "UNKNOWN_EVENT";
    }
  }

  static bool checkEvtDescriptorToDisplay(int evttype, int evtsubTyp, int rxpar0, int rxpar1, int rxpar2) {
    if ((evtTypeZone == evttype) && ((6 == evtsubTyp) || (7 == evtsubTyp))) {
      return false;
    } else if (evtTypeSupervisedInput == evttype) {
      return false;
    } else if (evtTypeSupervisedOutput == evttype) {
      return false;
    } else if (evtTypeZoneInput == evttype) {
      return false;
    } else if ((evtTypeGeneralEquipment == evttype) && (4 == evtsubTyp)) {
      return false;
    } else if ((evtTypeZoneEquipment == evttype) && (4 == evtsubTyp)) {
      return false;
    } else if ((evtTypeAreaEquipment == evttype) && (4 == evtsubTyp)) {
      return false;
    } else if ((evtTypeExtZoneEquipment == evttype) && (4 == evtsubTyp)) {
      return false;
    }
    return true;
  }

  static String getEventIdentifier(int evttype, int rxpar0, int rxpar1, int rxpar2) {
    String returnIdentifier = "-";

    try {
      if ((evtTypeZone == evttype) ||
          (evtTypeSupervisedInput == evttype) ||
          (evtTypeSupervisedOutput == evttype) ||
          (evtTypeZoneInput == evttype) ||
          (evtTypeExtZone == evttype)) {
        String valuePar0 = eventParam0NumberNameList[evttype]?.replaceAll('{par0}', rxpar0.toString()) ?? "";
        String valuePar1 = supervisoryFaultParam12Name[rxpar1] ?? "";
        returnIdentifier = "$valuePar0 $valuePar1";
      } else if ((evtTypeZoneEquipment == evttype) ||
          (evtTypeAreaEquipment == evttype) ||
          (evtTypeExtZoneEquipment == evttype)) {
        String valuePar1 = eventParam1NumberNameList[evttype]?.replaceAll('{par1}', rxpar1.toString()) ?? "";
        String valuePar2 = supervisoryFaultParam12Name[rxpar2] ?? "";
        returnIdentifier = "Equipment $valuePar1 $valuePar2";
      }
    } catch (e) {
      return returnIdentifier;
    }

    return returnIdentifier;
  }
} 