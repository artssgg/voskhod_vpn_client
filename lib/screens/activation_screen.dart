import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/device_identifier.dart';
import '../services/api_client.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final DeviceIdentifier _deviceId = DeviceIdentifier();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final ApiClient _apiClient;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: 'https://api.voskhodcore.com');
  }

  Future<void> _activate() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Введите токен');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fingerprint = await _deviceId.getDeviceFingerprint();
      final platform = Theme.of(context).platform == TargetPlatform.iOS ? 'ios' : 'android';

      final response = await _apiClient.activate(
        token,
        fingerprint,
        platform: platform,
      );

      print('🔍 Статус ответа: ${response.statusCode}');
      print('📦 Данные ответа: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        // Проверяем наличие vless_url – признак успеха
        if (data != null && data['vless_url'] != null) {
          await _storage.write(key: 'vless_url', value: data['vless_url']);
          await _storage.write(key: 'expires_at', value: data['expires_at']?.toString() ?? '');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          setState(() => _error = 'Ошибка активации: неверный формат ответа');
        }
      } else {
        setState(() => _error = 'Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Исключение: $e');
      setState(() => _error = 'Ошибка сети: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Активация VOSKHOD VPN')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Инвайт-токен',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _activate,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Активировать'),
            ),
          ],
        ),
      ),
    );
  }
}