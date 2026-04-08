import 'dart:convert';

/// Normalizes backend / AI JSON into editable diagnosis rows.
List<Map<String, dynamic>> parseDiagnosisList(dynamic value) {
  if (value == null) return [];
  if (value is String) {
    final t = value.trim();
    if (t.isEmpty) return [];
    final decoded = jsonDecode(t);
    return parseDiagnosisList(decoded);
  }
  if (value is! List) return [];
  return value.map((e) {
    if (e is Map) {
      return e.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{'name': e.toString(), 'code': ''};
  }).toList();
}

/// Normalizes medication rows (name, dose, frequency, duration, …).
List<Map<String, dynamic>> parseMedicationList(dynamic value) {
  if (value == null) return [];
  if (value is String) {
    final t = value.trim();
    if (t.isEmpty) return [];
    return parseMedicationList(jsonDecode(t));
  }
  if (value is! List) return [];
  return value.map((e) {
    if (e is Map) {
      return e.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{'name': e.toString()};
  }).toList();
}

List<Map<String, dynamic>> cloneMapList(List<Map<String, dynamic>> src) {
  return src.map((m) => Map<String, dynamic>.from(m)).toList();
}

/// Fields other than [code] and [name] (e.g. `confidence`) carried through the diagnosis list editor.
Map<String, dynamic> diagnosisPreservedFields(Map<String, dynamic> m) {
  final e = Map<String, dynamic>.from(m);
  e.remove('code');
  e.remove('name');
  return e;
}

/// Merges edited code/name with [preserved] fields from [diagnosisPreservedFields].
Map<String, dynamic> diagnosisMergeEditableIntoPreserved({
  required String code,
  required String name,
  required Map<String, dynamic> preserved,
}) {
  final map = Map<String, dynamic>.from(preserved);
  map['name'] = name;
  if (code.isNotEmpty) {
    map['code'] = code;
  } else {
    map.remove('code');
  }
  return map;
}

/// Drops rows with no code and no name.
List<Map<String, dynamic>> filterDiagnosisEntries(
  List<Map<String, dynamic>> raw,
) {
  return raw.where((m) {
    final name = '${m['name'] ?? ''}'.trim();
    final code = '${m['code'] ?? ''}'.trim();
    return name.isNotEmpty || code.isNotEmpty;
  }).toList();
}

/// Drops rows with empty medication name.
List<Map<String, dynamic>> filterMedicationEntries(
  List<Map<String, dynamic>> raw,
) {
  return raw.where((m) => '${m['name'] ?? ''}'.trim().isNotEmpty).toList();
}
