import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/profile.dart';

class ProfileStorage {
  static const _profileKey = 'profile';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveProfile(Profile profile) async {
    final jsonString = jsonEncode(profile.toJson());
    await _storage.write(key: _profileKey, value: jsonString);
  }

  Future<Profile?> loadProfile() async {
    final jsonString = await _storage.read(key: _profileKey);
    if (jsonString == null) return null;
    try {
      return Profile.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  Future<void> clearProfile() async {
    await _storage.delete(key: _profileKey);
  }
}