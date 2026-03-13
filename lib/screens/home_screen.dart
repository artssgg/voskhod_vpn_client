import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/device_identifier.dart';
import '../services/api_client.dart';
import '../services/vpn_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DeviceIdentifier _deviceId = DeviceIdentifier();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final ApiClient _apiClient;
  final VpnService _vpnService = VpnService();

  bool _isConnected = false;
  bool _isLoading = false;
  String _status = 'Отключено';
  String? _vlessUrl;
  String? _expiresAt;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: 'https://api.voskhodcore.com');
    _init();
  }

  Future<void> _init() async {
    await _vpnService.initialize();
    _loadData();
  }

  Future<void> _loadData() async {
    final url = await _storage.read(key: 'vless_url');
    final expires = await _storage.read(key: 'expires_at');
    setState(() {
      _vlessUrl = url;
      _expiresAt = expires;
    });
  }

  Future<void> _connect() async {
    setState(() {
      _isLoading = true;
      _status = 'Подключение...';
    });
    final success = await _vpnService.connect();
    setState(() {
      _isConnected = success;
      _status = success ? 'Подключено' : 'Ошибка подключения';
      _isLoading = false;
    });
  }

  Future<void> _disconnect() async {
    await _vpnService.disconnect();
    setState(() {
      _isConnected = false;
      _status = 'Отключено';
    });
  }

  Future<void> _rotateKey() async {
    setState(() => _isLoading = true);
    try {
      final fingerprint = await _deviceId.getDeviceFingerprint();
      final response = await _apiClient.rotate(fingerprint);
      if (response.statusCode == 200 && response.data['vless_url'] != null) {
        final newUrl = response.data['vless_url'];
        await _storage.write(key: 'vless_url', value: newUrl);
        setState(() {
          _vlessUrl = newUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ключ успешно обновлён')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при обновлении ключа')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'vless_url');
    await _storage.delete(key: 'expires_at');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VOSKHOD VPN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _rotateKey,
            tooltip: 'Перевыпустить ключ',
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('Статус', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _isConnected ? Colors.green : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : (_isConnected ? _disconnect : _connect),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isConnected ? 'Отключить' : 'Подключиться'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Убираем вызов _vpnService.dispose(), так как его больше нет
    super.dispose();
  }
}