import 'package:flutter/material.dart';
import 'package:vpn_app/l10n/app_localizations.dart';
import 'package:vpn_app/screens/registerScreen.dart';
import 'package:vpn_app/services/auth_service.dart';
import 'package:vpn_app/main.dart';
import 'package:vpn_app/screens/connectScreen.dart';
import 'package:vpn_app/services/settings_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    return Scaffold(
      backgroundColor: const Color(0xFF1C2363),
      body: Stack(
        children: [
          /// Top left shape  (same as WelcomeScreen)
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

          /// Top right shape  (same as WelcomeScreen)
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

          /// Bottom right shape  (same as WelcomeScreen)
          Positioned(
            bottom: -100,
            right: -50,
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                width: 180,
                height: 300,
                color: const Color(0xFF182056),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // ── Language toggle ──────────────────────────────────────
                  Align(
                    alignment: Alignment.topRight,
                    child: _LanguageToggle(isZh: isZh),
                  ),

                  const Spacer(),

                  /// Logo container  (same as WelcomeScreen)
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Image.asset(
                      'assets/logo/vpnlogo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    l.loginTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    l.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const Spacer(),

                  /// Email field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: l.emailHint,
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Colors.white54,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1B2160),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Password field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: l.passwordHint,
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.white54,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white54,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1B2160),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      l.forgotPassword,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Login button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter email and password'),
                            ),
                          );
                          return;
                        }
                        final result = await AuthService.login(
                          email: email,
                          password: password,
                        );
                        if (result.containsKey('token')) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ConnectScreen(),
                            ),
                          );
                        } else {
                          final errorMsg =
                              result['message'] ??
                              (result['errors'] != null
                                  ? result['errors'].values.first[0]
                                  : 'Login failed');
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(errorMsg)));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1C2363),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l.login,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Sign-up link
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                        children: [
                          TextSpan(text: l.noAccount),
                          TextSpan(
                            text: l.signUp,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language toggle chip (same as WelcomeScreen)
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  final bool isZh;
  const _LanguageToggle({required this.isZh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final newLang = isZh ? 'en' : 'zh';
        SettingsService.setString(SettingsService.languageKey, newLang);
        MyApp.of(
          context,
        ).setLocale(Locale(newLang));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2160),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF5C3BFF).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isZh ? '中' : 'EN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.language_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
