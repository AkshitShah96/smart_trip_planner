import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../models/web_user_model.dart';

class WebOnlyUserRepository {
  static const String _usersKey = 'smart_trip_planner_users';
  int _nextId = 1;

  WebOnlyUserRepository() {
    _initializeNextId();
  }

  void _initializeNextId() {
    final users = _getAllUsers();
    if (users.isNotEmpty) {
      final maxId = users.map((u) => u['id'] as int).reduce((a, b) => a > b ? a : b);
      _nextId = maxId + 1;
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  List<Map<String, dynamic>> _getAllUsers() {
    try {
      final usersJson = html.window.localStorage[_usersKey];
      if (usersJson != null) {
        final List<dynamic> usersList = json.decode(usersJson);
        return usersList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error reading users from localStorage: $e');
    }
    return [];
  }

  Future<void> _saveAllUsers(List<Map<String, dynamic>> users) async {
    try {
      final usersJson = json.encode(users);
      html.window.localStorage[_usersKey] = usersJson;
    } catch (e) {
      print('Error saving users to localStorage: $e');
    }
  }

  Future<WebUserModel> register(String name, String email, String password) async {
    final existingUser = _findUserByEmail(email);
    if (existingUser != null) {
      throw Exception('Email already registered');
    }

    final newUser = WebUserModel(
      id: _nextId++,
      email: email,
      name: name,
      passwordHash: _hashPassword(password),
      createdAt: DateTime.now(),
    );

    final users = _getAllUsers();
    users.add(newUser.toJson());
    await _saveAllUsers(users);
    return newUser;
  }

  Future<WebUserModel> login(String email, String password) async {
    final userData = _findUserByEmail(email);

    if (userData == null) {
      throw Exception('Invalid email or password');
    }

    final user = WebUserModel.fromJson(userData);
    
    if (user.passwordHash != _hashPassword(password)) {
      throw Exception('Invalid email or password');
    }

    // Update last login time
    final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
    final users = _getAllUsers();
    final index = users.indexWhere((u) => u['id'] == updatedUser.id);
    if (index != -1) {
      users[index] = updatedUser.toJson();
      await _saveAllUsers(users);
    }

    return updatedUser;
  }

  Map<String, dynamic>? _findUserByEmail(String email) {
    final users = _getAllUsers();
    print('Searching for email: $email in ${users.length} users');
    for (final user in users) {
      print('Found user email: ${user['email']}');
    }
    try {
      return users.firstWhere((user) => user['email'] == email);
    } catch (e) {
      return null;
    }
  }

  // Method to clear all users (for testing)
  Future<void> clearAllUsers() async {
    try {
      html.window.localStorage.remove(_usersKey);
      _nextId = 1;
      print('Cleared all users from localStorage');
    } catch (e) {
      print('Error clearing users: $e');
    }
  }

  // Method to get all users (for debugging)
  List<WebUserModel> getAllUsers() {
    final usersData = _getAllUsers();
    return usersData.map((data) => WebUserModel.fromJson(data)).toList();
  }
}

final webOnlyUserRepositoryProvider = Provider<WebOnlyUserRepository>((ref) {
  return WebOnlyUserRepository();
});
