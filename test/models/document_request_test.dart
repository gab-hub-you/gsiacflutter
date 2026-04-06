import 'package:flutter_test/flutter_test.dart';
import 'package:gsiac/models/document_request.dart';

void main() {
  group('DocumentRequest Model', () {
    final fullJson = {
      'tracking_number': 'TRK-A1B2C3D4',
      'type': 'Barangay Clearance',
      'purpose': 'Employment',
      'date_submitted': '2026-03-01T10:30:00.000Z',
      'status': 'pending',
      'issuing_office': 'barangay',
      'current_office': 'barangay',
      'rejection_reason': null,
      'attachment_path': 'https://example.com/doc.pdf',
    };

    test('fromJson parses all fields correctly', () {
      final request = DocumentRequest.fromJson(fullJson);

      expect(request.trackingNumber, 'TRK-A1B2C3D4');
      expect(request.type, 'Barangay Clearance');
      expect(request.purpose, 'Employment');
      expect(request.dateSubmitted, DateTime.utc(2026, 3, 1, 10, 30));
      expect(request.status, RequestStatus.pending);
      expect(request.issuingOffice, IssuingOffice.barangay);
      expect(request.currentOffice, IssuingOffice.barangay);
      expect(request.rejectionReason, isNull);
      expect(request.attachmentPath, 'https://example.com/doc.pdf');
    });

    test('toJson produces correct output', () {
      final request = DocumentRequest.fromJson(fullJson);
      final json = request.toJson();

      expect(json['tracking_number'], 'TRK-A1B2C3D4');
      expect(json['type'], 'Barangay Clearance');
      expect(json['status'], 'pending');
      expect(json['issuing_office'], 'barangay');
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final original = DocumentRequest.fromJson(fullJson);
      final roundtripped = DocumentRequest.fromJson(original.toJson());

      expect(roundtripped.trackingNumber, original.trackingNumber);
      expect(roundtripped.type, original.type);
      expect(roundtripped.status, original.status);
      expect(roundtripped.issuingOffice, original.issuingOffice);
    });

    test('statusText returns correct text for each status', () {
      final statuses = {
        'pending': 'Pending Review',
        'verifiedByBarangay': 'Verified by Barangay',
        'sentToMunicipal': 'Sent to Municipal',
        'processing': 'Processing',
        'completed': 'Completed',
        'rejected': 'Rejected',
      };

      for (final entry in statuses.entries) {
        final request = DocumentRequest.fromJson({...fullJson, 'status': entry.key});
        expect(request.statusText, entry.value);
      }
    });

    test('statusColor returns non-null for all statuses', () {
      for (final status in RequestStatus.values) {
        final request = DocumentRequest.fromJson({...fullJson, 'status': status.name});
        expect(request.statusColor, isNotNull);
      }
    });

    test('fromJson defaults to pending for unknown status', () {
      final json = {...fullJson, 'status': 'unknown'};
      final request = DocumentRequest.fromJson(json);
      expect(request.status, RequestStatus.pending);
    });

    test('fromJson defaults to barangay for unknown office', () {
      final json = {...fullJson, 'issuing_office': 'unknown', 'current_office': 'unknown'};
      final request = DocumentRequest.fromJson(json);
      expect(request.issuingOffice, IssuingOffice.barangay);
      expect(request.currentOffice, IssuingOffice.barangay);
    });
  });
}
