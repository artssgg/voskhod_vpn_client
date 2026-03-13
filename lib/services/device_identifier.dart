import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdentifier {
  static const String _secretKey = 'device_secret';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String> getDeviceFingerprint() async {
    String? secret = await _storage.read(key: _secretKey);
    if (secret == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      secret = base64Url.encode(bytes);
      await _storage.write(key: _secretKey, value: secret);
    }
    final hash = sha256.convert(utf8.encode(secret));
    return hash.toString(); // hex
  }

  Future<String> getDeviceSecret() async {
    String? secret = await _storage.read(key: _secretKey);
    if (secret == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      secret = base64Url.encode(bytes);
      await _storage.write(key: _secretKey, value: secret);
    }
    return secret;
  }
}