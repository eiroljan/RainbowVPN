import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vpn_app/l10n/app_localizations.dart';
import 'package:vpn_app/screens/welcomeScreen.dart';
import 'package:vpn_app/screens/connectScreen.dart';
import 'package:vpn_app/services/auth_service.dart';
import 'package:vpn_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hxbltzcbvumeiqcnnciw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4Ymx0emNidnVtZWlxY25uY2l3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzMzQxODUsImV4cCI6MjEwMTkxMDE4NX0.9ll87OxDwUVlq82q1DEobPejH8zgd8Zt3ooYGe8vqH8',
  );

  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  /// Allow any descendant widget to call [MyApp.setLocale] to switch language.
  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rainbow Brother VPN',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('zh'), // Simplified Chinese
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash / auto-login gate
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkLogin();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkLogin() async {
    // Small delay so the splash logo is briefly visible
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            loggedIn ? const ConnectScreen() : const WelcomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2363),
      body: Stack(
        children: [
          // ── Decorative shapes (same palette as all other screens) ──
          Positioned(
            top: -100,
            left: -80,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                width: 220,
                height: 450,
                color: const Color(0xFF5C3BFF),
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -70,
            child: Transform.rotate(
              angle: 0.1,
              child: Container(
                width: 180,
                height: 300,
                color: const Color(0xFF6A40FF),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: Transform.rotate(
              angle: -0.4,
              child: Container(width: 180, height: 300),
            ),
          ),

          // ── Centred logo + spinner ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _pulseAnim,
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Image.asset(
                      'assets/logo/vpnlogo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'RB VPN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF5C3BFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
