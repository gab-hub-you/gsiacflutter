import 'package:flutter_test/flutter_test.dart';
import 'package:gsiac/models/citizen.dart';

void main() {
  group('Citizen Model', () {
    final fullJson = {
      'id': 'test-uuid-1234',
      'username': 'jdoe',
      'profile_picture_url': 'https://example.com/pic.jpg',
      'first_name': 'John',
      'last_name': 'Doe',
      'middle_name': 'Michael',
      'suffix': 'Jr.',
      'sex': 'Male',
      'status': 'Single',
      'address': '123 Main St',
      'birthdate': '2000-01-15',
      'email': 'john@example.com',
      'phone_number': '09171234567',
      'town': 'Dagupan',
      'barangay': 'Poblacion',
      'gov_id_url': 'https://example.com/id.jpg',
      'selfie_url': 'https://example.com/selfie.jpg',
      'verification_status': 'verified',
      'life_status': 'Active',
      'role': 'citizen',
    };

    test('fromJson parses all fields correctly', () {
      final citizen = Citizen.fromJson(fullJson);

      expect(citizen.id, 'test-uuid-1234');
      expect(citizen.username, 'jdoe');
      expect(citizen.profilePictureUrl, 'https://example.com/pic.jpg');
      expect(citizen.firstName, 'John');
      expect(citizen.lastName, 'Doe');
      expect(citizen.middleName, 'Michael');
      expect(citizen.suffix, 'Jr.');
      expect(citizen.sex, 'Male');
      expect(citizen.status, 'Single');
      expect(citizen.address, '123 Main St');
      expect(citizen.birthdate, DateTime(2000, 1, 15));
      expect(citizen.email, 'john@example.com');
      expect(citizen.phoneNumber, '09171234567');
      expect(citizen.town, 'Dagupan');
      expect(citizen.barangay, 'Poblacion');
      expect(citizen.govIdUrl, 'https://example.com/id.jpg');
      expect(citizen.selfieUrl, 'https://example.com/selfie.jpg');
      expect(citizen.verificationStatus, VerificationStatus.verified);
      expect(citizen.lifeStatus, 'Active');
      expect(citizen.role, UserRole.citizen);
    });

    test('fromJson handles missing optional fields', () {
      final minimalJson = {
        'id': 'test-uuid',
        'first_name': 'Jane',
        'last_name': 'Doe',
        'address': '456 Oak Ave',
        'birthdate': '1995-06-20',
        'email': 'jane@example.com',
      };

      final citizen = Citizen.fromJson(minimalJson);

      expect(citizen.id, 'test-uuid');
      expect(citizen.username, '');
      expect(citizen.profilePictureUrl, isNull);
      expect(citizen.middleName, isNull);
      expect(citizen.suffix, isNull);
      expect(citizen.sex, isNull);
      expect(citizen.phoneNumber, isNull);
      expect(citizen.town, isNull);
      expect(citizen.barangay, isNull);
      expect(citizen.govIdUrl, isNull);
      expect(citizen.selfieUrl, isNull);
      expect(citizen.verificationStatus, VerificationStatus.unverified);
      expect(citizen.lifeStatus, 'Active');
      expect(citizen.role, UserRole.citizen);
    });

    test('toJson produces correct output', () {
      final citizen = Citizen.fromJson(fullJson);
      final json = citizen.toJson();

      expect(json['id'], 'test-uuid-1234');
      expect(json['first_name'], 'John');
      expect(json['last_name'], 'Doe');
      expect(json['middle_name'], 'Michael');
      expect(json['verification_status'], 'verified');
      expect(json['role'], 'citizen');
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final original = Citizen.fromJson(fullJson);
      final roundtripped = Citizen.fromJson(original.toJson());

      expect(roundtripped.id, original.id);
      expect(roundtripped.firstName, original.firstName);
      expect(roundtripped.lastName, original.lastName);
      expect(roundtripped.email, original.email);
      expect(roundtripped.verificationStatus, original.verificationStatus);
      expect(roundtripped.role, original.role);
    });

    test('fullName includes middle name and suffix', () {
      final citizen = Citizen.fromJson(fullJson);
      expect(citizen.fullName, 'John Michael Doe Jr.');
    });

    test('fullName without middle name and suffix', () {
      final citizen = Citizen.fromJson({
        ...fullJson,
        'middle_name': null,
        'suffix': null,
      });
      expect(citizen.fullName, 'John Doe');
    });

    test('displayName returns fullName when verified', () {
      final citizen = Citizen.fromJson(fullJson);
      expect(citizen.displayName, citizen.fullName);
    });

    test('displayName returns username when unverified', () {
      final citizen = Citizen.fromJson({
        ...fullJson,
        'verification_status': 'unverified',
      });
      expect(citizen.displayName, 'jdoe');
    });

    test('fromJson handles camelCase keys (auth metadata fallback)', () {
      final camelCaseJson = {
        'id': 'test-uuid',
        'firstName': 'Maria',
        'lastName': 'Santos',
        'middleName': 'Cruz',
        'profilePictureUrl': 'https://example.com/pic.jpg',
        'address': '789 Pine Rd',
        'birthdate': '1990-03-10',
        'email': 'maria@example.com',
        'phoneNumber': '09181234567',
        'govIdUrl': 'https://example.com/gov.jpg',
        'selfieUrl': 'https://example.com/self.jpg',
        'verificationStatus': 'pending',
      };

      final citizen = Citizen.fromJson(camelCaseJson);
      expect(citizen.firstName, 'Maria');
      expect(citizen.lastName, 'Santos');
      expect(citizen.middleName, 'Cruz');
      expect(citizen.profilePictureUrl, 'https://example.com/pic.jpg');
      expect(citizen.verificationStatus, VerificationStatus.pending);
    });

    test('fromJson defaults to unverified for unknown verification status', () {
      final json = {...fullJson, 'verification_status': 'unknown_value'};
      final citizen = Citizen.fromJson(json);
      expect(citizen.verificationStatus, VerificationStatus.unverified);
    });

    test('fromJson defaults to citizen for unknown role', () {
      final json = {...fullJson, 'role': 'admin'};
      final citizen = Citizen.fromJson(json);
      expect(citizen.role, UserRole.citizen);
    });
  });
}
