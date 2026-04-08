import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_app/features/scribe/domain/clinical_summary_lists.dart';

void main() {
  group('parseDiagnosisList', () {
    test('parses list of maps', () {
      final r = parseDiagnosisList([
        {'code': 'J06.9', 'name': 'Acute URI'},
        {'name': 'Headache'},
      ]);
      expect(r.length, 2);
      expect(r[0]['code'], 'J06.9');
      expect(r[0]['name'], 'Acute URI');
      expect(r[1]['name'], 'Headache');
    });

    test('parses JSON string', () {
      final r = parseDiagnosisList(
        '[{"code":"A","name":"B"}]',
      );
      expect(r.length, 1);
      expect(r[0]['code'], 'A');
    });

    test('filters empty diagnosis rows', () {
      final r = filterDiagnosisEntries([
        {'code': '', 'name': ''},
        {'code': 'X', 'name': ''},
        {'code': '', 'name': 'Y'},
      ]);
      expect(r.length, 2);
    });

    test('diagnosisPreservedFields strips only code and name', () {
      final p = diagnosisPreservedFields({
        'code': 'J06.9',
        'name': 'URI',
        'confidence': 0.91,
        'source': 'ai',
      });
      expect(p.containsKey('code'), false);
      expect(p.containsKey('name'), false);
      expect(p['confidence'], 0.91);
      expect(p['source'], 'ai');
    });

    test('diagnosisMergeEditableIntoPreserved keeps confidence', () {
      final out = diagnosisMergeEditableIntoPreserved(
        code: 'J00',
        name: 'Cold',
        preserved: {'confidence': 0.88, 'source': 'ai'},
      );
      expect(out['code'], 'J00');
      expect(out['name'], 'Cold');
      expect(out['confidence'], 0.88);
      expect(out['source'], 'ai');
    });

    test('diagnosisMergeEditableIntoPreserved drops empty code', () {
      final out = diagnosisMergeEditableIntoPreserved(
        code: '',
        name: 'Syndrome',
        preserved: {'confidence': 0.5},
      );
      expect(out.containsKey('code'), false);
      expect(out['name'], 'Syndrome');
      expect(out['confidence'], 0.5);
    });
  });

  group('parseMedicationList', () {
    test('parses maps with dose fields', () {
      final r = parseMedicationList([
        {
          'name': 'Paracetamol',
          'dose': '500mg',
          'frequency': 'TID',
          'duration': '5d',
        },
      ]);
      expect(r.length, 1);
      expect(r[0]['name'], 'Paracetamol');
      expect(r[0]['dose'], '500mg');
    });

    test('filterMedicationEntries requires name', () {
      final r = filterMedicationEntries([
        {'dose': '10mg'},
        {'name': '  Rx  ', 'dose': '1'},
      ]);
      expect(r.length, 1);
      expect(r[0]['name'], '  Rx  ');
    });
  });
}
