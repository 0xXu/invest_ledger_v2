import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../models/user.dart';
import '../../database/database_helper.dart';

class UserDao {
  static const String _tableName = 'users';

  Future<String> createUser({
    required String name,
    required String email,
  }) async {
    final db = await DatabaseHelper.database;
    final id = const Uuid().v4();

    final user = User(
      id: id,
      name: name,
      email: email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await db.insert(_tableName, {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'created_at': user.createdAt.toIso8601String(),
      'last_login_at': user.lastLoginAt?.toIso8601String(),
      'settings': jsonEncode(user.settings.toJson()),
    });

    return id;
  }

  Future<User?> getUserById(String id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return _mapToUser(maps.first);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isEmpty) return null;

    return _mapToUser(maps.first);
  }

  Future<List<User>> getAllUsers() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(_tableName);

    return maps.map(_mapToUser).toList();
  }

  Future<void> updateUser(User user) async {
    final db = await DatabaseHelper.database;
    await db.update(
      _tableName,
      {
        'name': user.name,
        'email': user.email,
        'last_login_at': user.lastLoginAt?.toIso8601String(),
        'settings': jsonEncode(user.settings.toJson()),
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> updateLastLogin(String userId) async {
    final db = await DatabaseHelper.database;
    await db.update(
      _tableName,
      {'last_login_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteUser(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  User _mapToUser(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      createdAt: DateTime.parse(map['created_at']),
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'])
          : null,
      settings: UserSettings.fromJson(jsonDecode(map['settings'])),
    );
  }
}
