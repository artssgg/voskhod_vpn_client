import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class DeviceIdentifier {
  static const _secretKey = 'device_secret';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Возвращает device_fingerprint (SHA256 от секрета)
  Future<String> getDeviceFingerprint() async {
    final secret = await _getOrCreateSecret();
    return sha256.convert(utf8.encode(secret)).toString(); // hex-строка
  }

  /// Возвращает сам секрет (нужен для подписи запросов)
  Future<String> getDeviceSecret() async {
    return _getOrCreateSecret();
  }

  Future<String> _getOrCreateSecret() async {
    String? secret = await _storage.read(key: _secretKey);
    if (secret == null) {
      secret = _generateRandomSecret();
      await _storage.write(key: _secretKey, value: secret);
    }
    return secret;
  }

  String _generateRandomSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes); // можно и hex, но base64 компактнее
  }
}