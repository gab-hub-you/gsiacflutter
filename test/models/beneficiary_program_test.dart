import 'package:flutter_test/flutter_test.dart';
import 'package:gsiac/models/beneficiary_program.dart';

void main() {
  group('BeneficiaryProgram Model', () {
    final fullJson = {
      'id': 'prog-uuid-1234',
      'name': '4Ps (Pantawid Pamilya)',
      'description': 'Conditional cash grants for the poor.',
      'type': 'financial',
      'requirements': ['ID Card', 'Barangay Indigency', 'Family Photo'],
      'payment_schedule': 'Monthly',
      'amount': 1500.0,
    };

    test('fromJson parses all fields correctly', () {
      final program = BeneficiaryProgram.fromJson(fullJson);

      expect(program.id, 'prog-uuid-1234');
      expect(program.name, '4Ps (Pantawid Pamilya)');
      expect(program.description, 'Conditional cash grants for the poor.');
      expect(program.type, BenefitType.financial);
      expect(program.requirements, ['ID Card', 'Barangay Indigency', 'Family Photo']);
      expect(program.paymentSchedule, 'Monthly');
      expect(program.amount, 1500.0);
    });

    test('fromJson handles null amount', () {
      final json = {...fullJson, 'amount': null};
      final program = BeneficiaryProgram.fromJson(json);
      expect(program.amount, isNull);
    });

    test('fromJson handles integer amount', () {
      final json = {...fullJson, 'amount': 3000};
      final program = BeneficiaryProgram.fromJson(json);
      expect(program.amount, 3000.0);
    });

    test('toJson produces correct output', () {
      final program = BeneficiaryProgram.fromJson(fullJson);
      final json = program.toJson();

      expect(json['id'], 'prog-uuid-1234');
      expect(json['name'], '4Ps (Pantawid Pamilya)');
      expect(json['type'], 'financial');
      expect(json['requirements'], hasLength(3));
      expect(json['payment_schedule'], 'Monthly');
      expect(json['amount'], 1500.0);
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final original = BeneficiaryProgram.fromJson(fullJson);
      final roundtripped = BeneficiaryProgram.fromJson(original.toJson());

      expect(roundtripped.id, original.id);
      expect(roundtripped.name, original.name);
      expect(roundtripped.type, original.type);
      expect(roundtripped.amount, original.amount);
      expect(roundtripped.requirements, original.requirements);
    });

    test('all benefit types parse correctly', () {
      for (final type in BenefitType.values) {
        final json = {...fullJson, 'type': type.name};
        final program = BeneficiaryProgram.fromJson(json);
        expect(program.type, type);
      }
    });

    test('fromJson defaults to financial for unknown type', () {
      final json = {...fullJson, 'type': 'unknown'};
      final program = BeneficiaryProgram.fromJson(json);
      expect(program.type, BenefitType.financial);
    });

    test('fromJson handles empty requirements', () {
      final json = {...fullJson, 'requirements': null};
      final program = BeneficiaryProgram.fromJson(json);
      expect(program.requirements, isEmpty);
    });

    test('fromJson defaults payment_schedule to Monthly', () {
      final json = Map<String, dynamic>.from(fullJson);
      json.remove('payment_schedule');
      final program = BeneficiaryProgram.fromJson(json);
      expect(program.paymentSchedule, 'Monthly');
    });
  });
}
