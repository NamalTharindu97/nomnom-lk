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
    this.avatarUrl,
  });

  factory AppUser.guest() {
    return const AppUser(
      id: 'guest',
      name: 'Guest',
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
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String id;
  final String name;
  final String email;
  final bool isLoggedIn;
  final bool isGuest;
  final String? phone;
  final String? role;
  final String? avatarUrl;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    bool? isLoggedIn,
    bool? isGuest,
    String? phone,
    String? role,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isGuest: isGuest ?? this.isGuest,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
