import 'package:flutter/material.dart';
import 'package:vpn_app/l10n/app_localizations.dart';
import 'package:vpn_app/main.dart';
import 'package:vpn_app/screens/loginScreen.dart';
import 'package:vpn_app/services/settings_service.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    return Scaffold(
      backgroundColor: const Color(0xFF1C2363),
      body: Stack(
        children: [
          /// Top left shape
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

          /// Top right shape
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

          /// Bottom right shape
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

                  /// Logo container
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
                    l.appTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    l.welcomeTagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1C2363),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l.getStarted,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                        children: [
                          TextSpan(text: l.alreadyHaveAccount),
                          TextSpan(
                            text: l.signIn,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Language toggle chip — shown on WelcomeScreen
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
