import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/activation_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VOSKHOD VPN',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<bool>(
        future: _checkIfActivated(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == true) {
            return const HomeScreen();
          } else {
            return const ActivationScreen();
          }
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
      },
    );
  }

  Future<bool> _checkIfActivated() async {
    const storage = FlutterSecureStorage();
    final vlessUrl = await storage.read(key: 'vless_url');
    return vlessUrl != null && vlessUrl.isNotEmpty;
  }
}