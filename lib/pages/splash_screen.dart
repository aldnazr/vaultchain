// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Color bgColor;

  @override
  void initState() {
    super.initState();
    bgColor = const Color.fromARGB(255, 255, 255, 255);
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final lastActive = prefs.getInt('lastActiveTime') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diffSeconds = ((now - lastActive) / 1000).round();
    if (!mounted) return;
    if (username != null) {
      if (diffSeconds >= 5) {
        Navigator.pushReplacementNamed(context, '/fingerprint_page');
      } else {
        Navigator.pushReplacementNamed(context, '/home_page');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login_page');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo/app_logo.png',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
