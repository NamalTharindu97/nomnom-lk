import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/models/app_user.dart';

void main() {
  group('AppUser', () {
    test('fromJson parses user', () {
      final json = {
        'id': 'u1',
        'name': 'Namal',
        'email': 'namal@test.com',
        'role': 'admin',
        'phone': '+94771234567',
        'avatar_url': 'https://img.com/avatar.jpg',
      };
      final user = AppUser.fromJson(json);
      expect(user.id, 'u1');
      expect(user.name, 'Namal');
      expect(user.email, 'namal@test.com');
      expect(user.role, 'admin');
      expect(user.phone, '+94771234567');
      expect(user.avatarUrl, 'https://img.com/avatar.jpg');
      expect(user.isLoggedIn, isTrue);
      expect(user.isGuest, isFalse);
    });

    test('guest factory', () {
      final guest = AppUser.guest();
      expect(guest.id, 'guest');
      expect(guest.name, 'Guest');
      expect(guest.email, '');
      expect(guest.isLoggedIn, isFalse);
      expect(guest.isGuest, isTrue);
    });

    test('copyWith updates name', () {
      const user = AppUser(id: 'u1', name: 'Old', email: 'e@t.com', isLoggedIn: true);
      final updated = user.copyWith(name: 'New');
      expect(updated.name, 'New');
      expect(updated.email, 'e@t.com');
    });

    test('copyWith preserves other fields', () {
      const user = AppUser(id: 'u1', name: 'N', email: 'e@t.com', isLoggedIn: true, role: 'admin');
      final updated = user.copyWith(name: 'N2');
      expect(updated.email, 'e@t.com');
      expect(updated.role, 'admin');
      expect(updated.isLoggedIn, isTrue);
    });
  });
}
