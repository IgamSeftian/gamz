import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

import 'database_service.dart';

/// Model sederhana untuk data user yang sedang login.
class UserModel {
  const UserModel({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
    );
  }
}

/// Service autentikasi lokal (register, login, logout).
///
/// Password tidak disimpan mentah, melainkan di-hash dengan SHA-256
/// supaya tidak mudah dibaca dari file database.
class AuthService {
  AuthService._();

  static Box get _users => DatabaseService.users;
  static Box get _session => DatabaseService.session;

  static const String _currentUserKey = 'currentUser';

  /// Hash password memakai SHA-256.
  static String _hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Mendaftarkan akun baru.
  ///
  /// Mengembalikan pesan error (String) jika gagal, atau `null` jika sukses.
  static Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();

    if (_users.containsKey(key)) {
      return 'Email sudah terdaftar. Silakan login.';
    }

    await _users.put(key, <String, dynamic>{
      'name': name.trim(),
      'email': key,
      'password': _hash(password),
      'createdAt': DateTime.now().toIso8601String(),
    });

    return null;
  }

  /// Login dengan email & password.
  ///
  /// Mengembalikan pesan error (String) jika gagal, atau `null` jika sukses.
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    final data = _users.get(key);

    if (data == null) {
      return 'Email belum terdaftar.';
    }

    final map = Map<dynamic, dynamic>.from(data as Map);
    if (map['password'] != _hash(password)) {
      return 'Password salah.';
    }

    await _session.put(_currentUserKey, key);
    return null;
  }

  /// Reset password untuk email yang sudah terdaftar.
  ///
  /// Mengembalikan pesan error (String) jika gagal, atau `null` jika sukses.
  static Future<String?> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final key = email.trim().toLowerCase();
    final data = _users.get(key);

    if (data == null) {
      return 'Email belum terdaftar.';
    }

    final map = Map<dynamic, dynamic>.from(data as Map);
    map['password'] = _hash(newPassword);
    map['updatedAt'] = DateTime.now().toIso8601String();
    await _users.put(key, map);
    return null;
  }

  /// Menghapus sesi login.
  static Future<void> logout() async {
    await _session.delete(_currentUserKey);
  }

  /// User yang sedang login, atau `null` jika belum login.
  static UserModel? get currentUser {
    final key = _session.get(_currentUserKey);
    if (key == null) return null;

    final data = _users.get(key);
    if (data == null) return null;

    return UserModel.fromMap(data as Map);
  }

  static bool get isLoggedIn => _session.get(_currentUserKey) != null;
}
