import 'package:flutter_v2ray_plus/flutter_v2ray.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VpnService {
  late final FlutterV2ray _v2ray;
  bool _isInitialized = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> initialize() async {
    if (_isInitialized) return;
    _v2ray = FlutterV2ray();
    _v2ray.onStatusChanged.listen((status) {
      print('VPN status: $status');
    });
    await _v2ray.initializeVless(
      providerBundleIdentifier: 'com.example.voskhodVpnClient.VPNProvider',
      groupIdentifier: 'group.com.example.voskhodVpnClient',
    );
    _isInitialized = true;
  }

  Future<bool> connect() async {
    if (!_isInitialized) await initialize();
    try {
      final vlessUrl = await _storage.read(key: 'vless_url');
      if (vlessUrl == null) {
        print('Нет сохранённого ключа');
        return false;
      }
      final parser = FlutterV2ray.parseFromURL(vlessUrl);
      final config = parser.getFullConfiguration();

      final allowed = await _v2ray.requestPermission();
      if (!allowed) throw Exception('Разрешение не получено');

      await _v2ray.startVless(
        remark: parser.remark.isNotEmpty ? parser.remark : 'VOSKHOD Server',
        config: config,
      );
      return true;
    } catch (e) {
      print('Ошибка подключения: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    if (!_isInitialized) return;
    await _v2ray.stopVless();
  }

  void dispose() {
    _v2ray.dispose();
  }
}