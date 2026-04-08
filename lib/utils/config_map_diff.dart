/// Deep comparison for JSON-like structures used in peripheral config snapshots.
class ConfigMapDiff {
  const ConfigMapDiff({
    required this.path,
    required this.local,
    required this.remote,
  });

  final String path;
  final String local;
  final String remote;
}

bool _numClose(num? a, num? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return (a - b).abs() < 1e-6;
}

/// Returns human-readable lines where [panel] differs from [baseline].
List<ConfigMapDiff> diffConfigValues(
  Object? baseline,
  Object? panel, {
  String path = '',
  bool diagnosticsMode = false,
}) {
  final out = <ConfigMapDiff>[];

  if (baseline == null && panel == null) return out;

  if (baseline is Map && panel is Map) {
    final bm = baseline as Map;
    final pm = panel as Map;
    final keys = {
      ...bm.keys.map((e) => e.toString()),
      ...pm.keys.map((e) => e.toString()),
    };
    for (final k in keys) {
      final bk = bm[k];
      final pk = pm[k];
      out.addAll(
        diffConfigValues(
          bk,
          pk,
          path: path.isEmpty ? k : '$path.$k',
          diagnosticsMode: diagnosticsMode,
        ),
      );
    }
    return out;
  }

  if (baseline is List && panel is List) {
    final bl = baseline as List;
    final pl = panel as List;
    final len = bl.length > pl.length ? bl.length : pl.length;
    for (var i = 0; i < len; i++) {
      final bk = i < bl.length ? bl[i] : null;
      final pk = i < pl.length ? pl[i] : null;
      out.addAll(
        diffConfigValues(
          bk,
          pk,
          path: '$path[$i]',
          diagnosticsMode: diagnosticsMode,
        ),
      );
    }
    return out;
  }

  if (diagnosticsMode && baseline is num && panel is num) {
    if (!_numClose(baseline, panel)) {
      out.add(
        ConfigMapDiff(
          path: path,
          local: baseline.toString(),
          remote: panel.toString(),
        ),
      );
    }
    return out;
  }

  if (baseline == panel) return out;

  String fmt(Object? v) {
    if (v == null) return 'null';
    return v.toString();
  }

  out.add(ConfigMapDiff(path: path, local: fmt(baseline), remote: fmt(panel)));
  return out;
}
