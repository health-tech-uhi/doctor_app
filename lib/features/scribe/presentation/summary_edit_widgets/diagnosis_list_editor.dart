import 'package:flutter/material.dart';

import '../../../../core/theme/doctor_theme.dart';
import '../../domain/clinical_summary_lists.dart';

/// Editable ICD-style diagnosis rows (code + name).
class DiagnosisListEditor extends StatefulWidget {
  const DiagnosisListEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> initial;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  @override
  State<DiagnosisListEditor> createState() => _DiagnosisListEditorState();
}

class _DiagnosisListEditorState extends State<DiagnosisListEditor> {
  late List<_DxRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.initial.map(_DxRow.fromMap).toList();
    if (_rows.isEmpty) {
      _rows = [_DxRow.empty()];
    }
  }

  void _notify() {
    widget.onChanged(_rows.map((e) => e.toMap()).toList());
  }

  void _add() {
    setState(() {
      _rows.add(_DxRow.empty());
      _notify();
    });
  }

  void _remove(int i) {
    setState(() {
      if (_rows.length <= 1) {
        _rows = [_DxRow.empty()];
      } else {
        _rows.removeAt(i);
      }
      _notify();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Diagnoses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DoctorTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...List.generate(_rows.length, (i) {
          final r = _rows[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DoctorTheme.glassSurface.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DoctorTheme.glassStroke),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: r.code,
                            decoration: const InputDecoration(
                              labelText: 'Code',
                              isDense: true,
                            ),
                            style: const TextStyle(
                              color: DoctorTheme.textPrimary,
                              fontSize: 14,
                            ),
                            onChanged: (_) => _notify(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _remove(i),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                    TextField(
                      controller: r.name,
                      decoration: const InputDecoration(
                        labelText: 'Name / description',
                        isDense: true,
                      ),
                      style: const TextStyle(
                        color: DoctorTheme.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      onChanged: (_) => _notify(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }
}

class _DxRow {
  _DxRow({
    required this.code,
    required this.name,
    Map<String, dynamic>? preserved,
  }) : _preserved = preserved ?? {};

  factory _DxRow.empty() => _DxRow(
        code: TextEditingController(),
        name: TextEditingController(),
      );

  factory _DxRow.fromMap(Map<String, dynamic> m) {
    return _DxRow(
      code: TextEditingController(text: '${m['code'] ?? ''}'.trim()),
      name: TextEditingController(text: '${m['name'] ?? ''}'.trim()),
      preserved: diagnosisPreservedFields(m),
    );
  }

  final TextEditingController code;
  final TextEditingController name;
  final Map<String, dynamic> _preserved;

  Map<String, dynamic> toMap() {
    return diagnosisMergeEditableIntoPreserved(
      code: code.text.trim(),
      name: name.text.trim(),
      preserved: _preserved,
    );
  }

  void dispose() {
    code.dispose();
    name.dispose();
  }
}
