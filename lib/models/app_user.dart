import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isLoggedIn,
    this.isGuest = false,
    this.phone,
    this.role,
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

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isLoggedIn: true,
      isGuest: false,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
    );
  }

  final String id;
  final String name;
  final String email;
  final bool isLoggedIn;
  final bool isGuest;
  final String? phone;
  final String? role;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    bool? isLoggedIn,
    bool? isGuest,
    String? phone,
    String? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isGuest: isGuest ?? this.isGuest,
      phone: phone ?? this.phone,
      role: role ?? this.role,
    );
  }
}
