import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthService>();
    await auth.init();
    if (auth.isLoggedIn) {
      context.read<ApiService>().setToken(auth.token);
    }
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A5276),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('RMC',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('PNWHS bin Qasim',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('Resident Management Center',
                style: TextStyle(fontSize: 13, color: Colors.white70, letterSpacing: 1)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
          ]),
        ),
      ),
    );
  }
}
