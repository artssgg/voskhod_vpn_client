import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'device_identifier.dart';

class ApiClient {
  final Dio _dio;
  final DeviceIdentifier _deviceIdentifier;
  final String baseUrl;

  ApiClient({required this.baseUrl})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl)),
        _deviceIdentifier = DeviceIdentifier();

  // --- Методы с подписью (если понадобятся) ---
  Future<Options> _signedOptions({Map<String, dynamic>? data}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final secret = await _deviceIdentifier.getDeviceSecret();
    final body = data != null ? jsonEncode(data) : '';
    final signature = _hmacSha256(secret, '$timestamp$body');
    return Options(headers: {
      'X-Timestamp': timestamp.toString(),
      'X-Signature': signature,
    });
  }

  String _hmacSha256(String key, String data) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(data)).toString(); // hex
  }

  Future<Response> postSigned(String path, Map<String, dynamic> data) async {
    final options = await _signedOptions(data: data);
    return _dio.post(path, data: data, options: options);
  }

  Future<Response> getSigned(String path) async {
    final options = await _signedOptions();
    return _dio.get(path, options: options);
  }

  // --- Методы без подписи для текущего API ---
  Future<Response> activate(String token, String deviceFingerprint,
      {String deviceLabel = 'Flutter', String platform = 'android'}) async {
    return _dio.post('/activate', data: {
      'invite_token': token,
      'device_fingerprint': deviceFingerprint,
      'device_label': deviceLabel,
      'platform': platform,
      'tg_user_id': 0,          // фиктивное значение, можно 0
      'username': '',            // пустая строка
    });
  }

  Future<Response> rotate(String deviceFingerprint) async {
    return _dio.post('/rotate', data: {
      'device_fingerprint': deviceFingerprint,
    });
  }
}