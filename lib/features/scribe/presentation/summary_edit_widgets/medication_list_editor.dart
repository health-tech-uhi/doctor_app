import 'package:flutter/material.dart';

import '../../../../core/theme/doctor_theme.dart';

/// Editable medication rows (name, dose, frequency, duration).
class MedicationListEditor extends StatefulWidget {
  const MedicationListEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> initial;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  @override
  State<MedicationListEditor> createState() => _MedicationListEditorState();
}

class _MedicationListEditorState extends State<MedicationListEditor> {
  late List<_MedRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.initial.map(_MedRow.fromMap).toList();
    if (_rows.isEmpty) {
      _rows = [_MedRow.empty()];
    }
  }

  void _notify() {
    widget.onChanged(_rows.map((e) => e.toMap()).toList());
  }

  void _add() {
    setState(() {
      _rows.add(_MedRow.empty());
      _notify();
    });
  }

  void _remove(int i) {
    setState(() {
      if (_rows.length <= 1) {
        _rows = [_MedRow.empty()];
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
                'Medications',
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
                      children: [
                        Expanded(
                          child: TextField(
                            controller: r.name,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              isDense: true,
                            ),
                            style: const TextStyle(
                              color: DoctorTheme.textPrimary,
                              fontSize: 14,
                            ),
                            onChanged: (_) => _notify(),
                          ),
                        ),
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
                      controller: r.dose,
                      decoration: const InputDecoration(
                        labelText: 'Dose',
                        isDense: true,
                      ),
                      style: const TextStyle(
                        color: DoctorTheme.textPrimary,
                        fontSize: 14,
                      ),
                      onChanged: (_) => _notify(),
                    ),
                    TextField(
                      controller: r.frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        isDense: true,
                      ),
                      style: const TextStyle(
                        color: DoctorTheme.textPrimary,
                        fontSize: 14,
                      ),
                      onChanged: (_) => _notify(),
                    ),
                    TextField(
                      controller: r.duration,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        isDense: true,
                      ),
                      style: const TextStyle(
                        color: DoctorTheme.textPrimary,
                        fontSize: 14,
                      ),
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

class _MedRow {
  _MedRow({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.duration,
  });

  factory _MedRow.empty() => _MedRow(
        name: TextEditingController(),
        dose: TextEditingController(),
        frequency: TextEditingController(),
        duration: TextEditingController(),
      );

  factory _MedRow.fromMap(Map<String, dynamic> m) {
    String s(String k) => '${m[k] ?? ''}'.trim();
    return _MedRow(
      name: TextEditingController(text: s('name')),
      dose: TextEditingController(text: s('dose')),
      frequency: TextEditingController(text: s('frequency')),
      duration: TextEditingController(text: s('duration')),
    );
  }

  final TextEditingController name;
  final TextEditingController dose;
  final TextEditingController frequency;
  final TextEditingController duration;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    void put(String k, String v) {
      if (v.isNotEmpty) map[k] = v;
    }

    put('name', name.text.trim());
    put('dose', dose.text.trim());
    put('frequency', frequency.text.trim());
    put('duration', duration.text.trim());
    return map;
  }

  void dispose() {
    name.dispose();
    dose.dispose();
    frequency.dispose();
    duration.dispose();
  }
}
