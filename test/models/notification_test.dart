import 'package:flutter_test/flutter_test.dart';
import 'package:gsiac/models/notification.dart';

void main() {
  group('AppNotification Model', () {
    final fullJson = {
      'id': 'notif-uuid-1234',
      'title': 'Request Submitted',
      'message': 'Your request for Barangay Clearance has been submitted.',
      'timestamp': '2026-03-15T10:30:00.000Z',
      'type': 'success',
      'is_read': false,
    };

    test('fromJson parses all fields correctly', () {
      final notif = AppNotification.fromJson(fullJson);

      expect(notif.id, 'notif-uuid-1234');
      expect(notif.title, 'Request Submitted');
      expect(notif.message, 'Your request for Barangay Clearance has been submitted.');
      expect(notif.timestamp, DateTime.utc(2026, 3, 15, 10, 30));
      expect(notif.type, NotificationType.success);
      expect(notif.isRead, false);
    });

    test('fromJson handles read notification', () {
      final json = {...fullJson, 'is_read': true};
      final notif = AppNotification.fromJson(json);
      expect(notif.isRead, true);
    });

    test('toJson produces correct output', () {
      final notif = AppNotification.fromJson(fullJson);
      final json = notif.toJson();

      expect(json['id'], 'notif-uuid-1234');
      expect(json['title'], 'Request Submitted');
      expect(json['type'], 'success');
      expect(json['is_read'], false);
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final original = AppNotification.fromJson(fullJson);
      final roundtripped = AppNotification.fromJson(original.toJson());

      expect(roundtripped.id, original.id);
      expect(roundtripped.title, original.title);
      expect(roundtripped.message, original.message);
      expect(roundtripped.type, original.type);
      expect(roundtripped.isRead, original.isRead);
    });

    test('all notification types parse correctly', () {
      for (final type in NotificationType.values) {
        final json = {...fullJson, 'type': type.name};
        final notif = AppNotification.fromJson(json);
        expect(notif.type, type);
      }
    });

    test('fromJson defaults to info for unknown type', () {
      final json = {...fullJson, 'type': 'unknown'};
      final notif = AppNotification.fromJson(json);
      expect(notif.type, NotificationType.info);
    });

    test('fromJson defaults is_read to false if missing', () {
      final json = Map<String, dynamic>.from(fullJson);
      json.remove('is_read');
      final notif = AppNotification.fromJson(json);
      expect(notif.isRead, false);
    });

    test('isRead is mutable', () {
      final notif = AppNotification.fromJson(fullJson);
      expect(notif.isRead, false);
      notif.isRead = true;
      expect(notif.isRead, true);
    });

    test('fromJson handles numeric id', () {
      final json = {...fullJson, 'id': 42};
      final notif = AppNotification.fromJson(json);
      expect(notif.id, '42');
    });
  });
}
