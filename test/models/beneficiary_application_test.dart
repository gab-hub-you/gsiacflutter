import 'package:flutter_test/flutter_test.dart';
import 'package:gsiac/models/beneficiary_application.dart';

void main() {
  group('BeneficiaryApplication Model', () {
    final fullJson = {
      'id': 'app-uuid-1234',
      'citizen_id': 'citizen-uuid-5678',
      'program_id': 'prog-uuid-9012',
      'program_name': '4Ps (Pantawid Pamilya)',
      'status': 'pending_barangay',
      'tracking_id': 'BEN-A1B2C3D4',
      'date_submitted': '2026-03-15T14:00:00.000Z',
      'supporting_docs': ['https://example.com/doc1.pdf', 'https://example.com/doc2.pdf'],
      'qr_code': null,
      'remarks': null,
      'approval_date': null,
    };

    test('fromJson parses all fields correctly', () {
      final app = BeneficiaryApplication.fromJson(fullJson);

      expect(app.id, 'app-uuid-1234');
      expect(app.citizenId, 'citizen-uuid-5678');
      expect(app.programId, 'prog-uuid-9012');
      expect(app.programName, '4Ps (Pantawid Pamilya)');
      expect(app.status, ApplicationStatus.pendingBarangay);
      expect(app.trackingId, 'BEN-A1B2C3D4');
      expect(app.dateSubmitted, DateTime.utc(2026, 3, 15, 14, 0));
      expect(app.supportingDocs, hasLength(2));
      expect(app.qrCode, isNull);
      expect(app.remarks, isNull);
      expect(app.approvalDate, isNull);
    });

    test('fromJson parses approved status with approval date', () {
      final approvedJson = {
        ...fullJson,
        'status': 'approved',
        'qr_code': 'QR-app-uuid-1234',
        'approval_date': '2026-03-20T10:00:00.000Z',
        'remarks': 'All documents verified.',
      };

      final app = BeneficiaryApplication.fromJson(approvedJson);
      expect(app.status, ApplicationStatus.approved);
      expect(app.qrCode, 'QR-app-uuid-1234');
      expect(app.approvalDate, DateTime.utc(2026, 3, 20, 10, 0));
      expect(app.remarks, 'All documents verified.');
    });

    test('toJson produces correct output', () {
      final app = BeneficiaryApplication.fromJson(fullJson);
      final json = app.toJson();

      expect(json['id'], 'app-uuid-1234');
      expect(json['citizen_id'], 'citizen-uuid-5678');
      expect(json['status'], 'pending_barangay');
      expect(json['supporting_docs'], hasLength(2));
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final original = BeneficiaryApplication.fromJson(fullJson);
      final roundtripped = BeneficiaryApplication.fromJson(original.toJson());

      expect(roundtripped.id, original.id);
      expect(roundtripped.citizenId, original.citizenId);
      expect(roundtripped.status, original.status);
      expect(roundtripped.trackingId, original.trackingId);
    });

    test('statusToDb converts correctly', () {
      expect(BeneficiaryApplication.statusToDb(ApplicationStatus.pendingBarangay), 'pending_barangay');
      expect(BeneficiaryApplication.statusToDb(ApplicationStatus.pendingMunicipal), 'pending_municipal');
      expect(BeneficiaryApplication.statusToDb(ApplicationStatus.approved), 'approved');
      expect(BeneficiaryApplication.statusToDb(ApplicationStatus.rejected), 'rejected');
      expect(BeneficiaryApplication.statusToDb(ApplicationStatus.suspended), 'suspended');
    });

    test('statusFromDb converts correctly', () {
      expect(BeneficiaryApplication.statusFromDb('pending_barangay'), ApplicationStatus.pendingBarangay);
      expect(BeneficiaryApplication.statusFromDb('pending_municipal'), ApplicationStatus.pendingMunicipal);
      expect(BeneficiaryApplication.statusFromDb('approved'), ApplicationStatus.approved);
      expect(BeneficiaryApplication.statusFromDb(null), ApplicationStatus.pendingBarangay);
    });

    test('fromJson defaults to pendingBarangay for unknown status', () {
      final json = {...fullJson, 'status': 'unknown_status'};
      final app = BeneficiaryApplication.fromJson(json);
      expect(app.status, ApplicationStatus.pendingBarangay);
    });

    test('fromJson handles empty supporting docs', () {
      final json = {...fullJson, 'supporting_docs': null};
      final app = BeneficiaryApplication.fromJson(json);
      expect(app.supportingDocs, isEmpty);
    });

    test('fromJson handles missing program name', () {
      final json = {...fullJson, 'program_name': null};
      final app = BeneficiaryApplication.fromJson(json);
      expect(app.programName, 'Social Program');
    });
  });
}
