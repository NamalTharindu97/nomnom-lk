import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isLoggedIn,
    this.isGuest = false,
  });

  factory AppUser.guest() {
    return const AppUser(
      id: 'guest',
      name: 'Guest foodie',
      email: '',
      isLoggedIn: false,
      isGuest: true,
    );
  }

  final String id;
  final String name;
  final String email;
  final bool isLoggedIn;
  final bool isGuest;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    bool? isLoggedIn,
    bool? isGuest,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}
