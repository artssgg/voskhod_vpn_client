import 'package:flutter/material.dart';
import '../services/profile_storage.dart';
import '../services/api_client.dart';
import '../models/profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiClient = ApiClient(baseUrl: 'https://ваш-сервер.com');
  final _profileStorage = ProfileStorage();

  Profile? _profile;
  Map<String, dynamic>? _statusData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileStorage.loadProfile();
      if (profile == null) throw Exception('Профиль не найден');
      _profile = profile;

      final response = await _apiClient.getSigned('/v1/status?device_id=${profile.deviceId}');
      if (response.statusCode == 200) {
        setState(() {
          _statusData = response.data;
          _error = null;
        });
      } else {
        throw Exception('Ошибка загрузки статуса');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rotateKey() async {
    if (_profile == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.postSigned('/v1/rotate', {
        'device_id': _profile!.deviceId,
      });
      if (response.statusCode == 200) {
        final newVlessUrl = response.data['vless_url'];
        // Обновляем профиль в хранилище
        final updatedProfile = Profile(
          deviceId: _profile!.deviceId,
          subscriptionId: _profile!.subscriptionId,
          vlessUrl: newVlessUrl,
          planCode: _profile!.planCode,
          expiresAt: _profile!.expiresAt,
        );
        await _profileStorage.saveProfile(updatedProfile);
        setState(() => _profile = updatedProfile);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ключ успешно обновлён')),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Ошибка: $_error'),
              ElevatedButton(onPressed: _loadData, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    final status = _statusData?['status'] ?? 'active'; // active/blocked/expired
    final planCode = _profile!.planCode;
    final expiresAt = _profile!.expiresAt;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('План', planCode),
            const SizedBox(height: 16),
            _buildInfoRow('Статус', status, color: status == 'active' ? Colors.green : Colors.red),
            const SizedBox(height: 16),
            _buildInfoRow('Действует до', '${expiresAt.day}.${expiresAt.month}.${expiresAt.year}'),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _rotateKey,
                child: const Text('Перевыпустить ключ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}