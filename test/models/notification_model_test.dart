import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/models/notification_model.dart';

void main() {
  group('AppNotification', () {
    test('fromJson parses notification', () {
      final json = {
        'id': 'n1',
        'type': 'admin',
        'title': 'New Offer',
        'body': 'Check out this deal',
        'is_read': false,
        'created_at': '2026-07-20T10:00:00Z',
        'offer_id': 'o1',
        'image_url': 'https://img.com/offer.jpg',
      };
      final n = AppNotification.fromJson(json);
      expect(n.id, 'n1');
      expect(n.type, 'admin');
      expect(n.title, 'New Offer');
      expect(n.body, 'Check out this deal');
      expect(n.isRead, isFalse);
      expect(n.offerId, 'o1');
      expect(n.imageUrl, 'https://img.com/offer.jpg');
      expect(n.createdAt.year, 2026);
    });

    test('fromJson handles null image_url', () {
      final json = {
        'id': 'n2',
        'type': 'admin',
        'title': 'Test',
        'is_read': true,
        'created_at': '2026-07-20T10:00:00Z',
      };
      final n = AppNotification.fromJson(json);
      expect(n.offerId, isNull);
      expect(n.imageUrl, isNull);
    });

    test('toJson roundtrip', () {
      final json = {
        'id': 'n3',
        'type': 'promo',
        'title': 'Sale',
        'body': 'Big sale',
        'is_read': false,
        'created_at': '2026-07-20T10:00:00Z',
        'offer_id': 'o2',
        'image_url': 'https://img.com/x.jpg',
      };
      final n = AppNotification.fromJson(json);
      final back = n.toJson();
      expect(back['id'], 'n3');
      expect(back['type'], 'promo');
      expect(back['offer_id'], 'o2');
      expect(back['image_url'], 'https://img.com/x.jpg');
    });

    test('copyWith updates isRead', () {
      final json = {
        'id': 'n4',
        'type': 'admin',
        'title': 'T',
        'body': 'B',
        'is_read': false,
        'created_at': '2026-07-20T10:00:00Z',
      };
      final n = AppNotification.fromJson(json);
      final read = n.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.id, 'n4');
      expect(read.title, 'T');
    });
  });
}
