import 'dart:typed_data';

import 'package:Technoswitch/config/structs/struct_bytes.dart';

/// Mirrors firmware `st_module_id_data_def` (30 bytes, packed).
///
/// This is the module-id response payload. The connect request does not send it.
class ModuleIdDataDef {
  const ModuleIdDataDef({
    required this.moduleTypeId,
    required this.moduleType,
    required this.moduleRev,
    required this.moduleName,
    required this.hdwMajor,
    required this.hdwMinor,
    required this.hdwOption,
    required this.hdwVrsn,
    required this.swMajor,
    required this.swMinor,
    required this.swRelease,
    required this.swBuild,
    required this.swDate,
    required this.swYear,
    required this.swMonth,
    required this.swDay,
    required this.swProtocol,
  });

  static const int moduleNameLength = 11;
  static const int byteLength = 30;

  final int moduleTypeId;
  final int moduleType;
  final int moduleRev;
  final String moduleName;
  final int hdwMajor;
  final int hdwMinor;
  final int hdwOption;
  final int hdwVrsn;
  final int swMajor;
  final int swMinor;
  final int swRelease;
  final int swBuild;
  final int swDate;
  final int swYear;
  final int swMonth;
  final int swDay;
  final int swProtocol;

  factory ModuleIdDataDef.fromBytes(Uint8List bytes, {int offset = 0}) {
    if (offset < 0 || offset + byteLength > bytes.length) {
      throw RangeError(
        'ModuleIdDataDef requires $byteLength bytes at offset $offset',
      );
    }
    return ModuleIdDataDef(
      moduleTypeId: StructBytes.readUint16Le(bytes, offset),
      moduleType: bytes[offset + 2],
      moduleRev: bytes[offset + 3],
      moduleName: StructBytes.readFixedText(
        bytes,
        offset + 4,
        moduleNameLength,
      ),
      hdwMajor: bytes[offset + 15],
      hdwMinor: bytes[offset + 16],
      hdwOption: bytes[offset + 17],
      hdwVrsn: bytes[offset + 18],
      swMajor: bytes[offset + 19],
      swMinor: bytes[offset + 20],
      swRelease: bytes[offset + 21],
      swBuild: bytes[offset + 22],
      swDate: bytes[offset + 23],
      swYear: StructBytes.readUint16Le(bytes, offset + 24),
      swMonth: bytes[offset + 26],
      swDay: bytes[offset + 27],
      swProtocol: StructBytes.readUint16Le(bytes, offset + 28),
    );
  }
}
