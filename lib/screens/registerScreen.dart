import 'package:flutter/material.dart';
import 'package:vpn_app/l10n/app_localizations.dart';
import 'package:vpn_app/main.dart';
import 'package:vpn_app/screens/paymentSheet.dart';
import 'package:vpn_app/services/auth_service.dart';
import 'package:vpn_app/screens/connectScreen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // ── Step tracking ──────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // ── Step 1: account fields ─────────────────────────────────────────────────
  bool _obscurePassword = true;
  bool _isRegistering = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ── Step 2: plan selection ─────────────────────────────────────────────────
  List<Map<String, dynamic>> _plans = [];
  bool _loadingPlans = true;
  String? _selectedPlanId;
  bool _subscribing = false;

  // ── Shimmer ────────────────────────────────────────────────────────────────
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor:
            success ? const Color(0xFF1A3A2A) : const Color(0xFF3A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _planIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('free')) return '🆓';
    if (n.contains('basic')) return '⚡';
    if (n.contains('pro') || n.contains('premium')) return '👑';
    if (n.contains('ultimate') || n.contains('max')) return '🚀';
    return '✨';
  }

  int _recommendedIndex() => _plans.length > 1 ? _plans.length - 2 : 0;

  Widget _shimmerBox({required double height, double radius = 12}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) => Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: const Alignment(-1.5, -0.5),
            end: const Alignment(1.5, 0.5),
            stops: [
              (_shimmerController.value - 0.3).clamp(0.0, 1.0),
              _shimmerController.value.clamp(0.0, 1.0),
              (_shimmerController.value + 0.3).clamp(0.0, 1.0),
            ],
            colors: const [
              Color(0xFF1B2160),
              Color(0xFF2A3280),
              Color(0xFF1B2160),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1 action: register account ────────────────────────────────────────

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }

    setState(() => _isRegistering = true);
    final result = await AuthService.register(
        name: name, email: email, password: password);
    if (!mounted) return;
    setState(() => _isRegistering = false);

    if (result.containsKey('token')) {
      _fetchPlans();
      setState(() => _currentStep = 1);
      _pageController.animateToPage(1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    } else {
      final errorMsg = result['message'] ??
          (result['errors'] != null
              ? result['errors'].values.first[0]
              : 'Registration failed');
      _showSnack(errorMsg);
    }
  }

  Future<void> _fetchPlans() async {
    setState(() => _loadingPlans = true);
    final result = await AuthService.getPlans();
    if (!mounted) return;
    setState(() {
      _plans = List<Map<String, dynamic>>.from(result['plans'] ?? []);
      _loadingPlans = false;
      if (_plans.isNotEmpty) {
        _selectedPlanId = _plans[_recommendedIndex()]['id']?.toString();
      }
    });
  }

  // ── Step 2 action: subscribe then go to app ─────────────────────────────────

  Future<void> _handleFinish() async {
    if (_selectedPlanId == null) {
      _goToApp();
      return;
    }

    final selected = _plans.firstWhere(
      (p) => p['id']?.toString() == _selectedPlanId,
      orElse: () => {},
    );
    final price =
        double.tryParse(selected['price']?.toString() ?? '0') ?? 0;
    final planName = selected['name']?.toString() ?? 'Plan';

    // Show card payment sheet for paid plans
    if (price > 0) {
      final paid = await showPaymentSheet(
        context,
        amount: price,
        planName: planName,
      );
      if (!paid || !mounted) return; // User dismissed — stay on step 2
    }

    setState(() => _subscribing = true);
    final planId = int.tryParse(_selectedPlanId!) ?? 0;
    final result = await AuthService.subscribe(planId);
    if (!mounted) return;
    setState(() => _subscribing = false);

    if (result.containsKey('subscription')) {
      _showSnack('🎉 ${result['message'] ?? 'Subscribed!'}', success: true);
    } else {
      _showSnack(result['message'] ?? 'Could not subscribe, you can do it later.');
    }
    _goToApp();
  }

  void _goToApp() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ConnectScreen()),
      (_) => false,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    return Scaffold(
      backgroundColor: const Color(0xFF1C2363),
      body: Stack(
        children: [
          Positioned(
            top: -100, left: -80,
            child: Transform.rotate(angle: -0.3,
              child: Container(width: 220, height: 450, color: const Color(0xFF5C3BFF))),
          ),
          Positioned(
            top: -50, right: -70,
            child: Transform.rotate(angle: 0.1,
              child: Container(width: 180, height: 300, color: const Color(0xFF6A40FF))),
          ),
          Positioned(
            bottom: -100, right: -50,
            child: Transform.rotate(angle: -0.4,
              child: Container(width: 180, height: 300, color: const Color(0xFF182056))),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () {
                          if (_currentStep == 1) {
                            setState(() => _currentStep = 0);
                            _pageController.animateToPage(0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StepProgressBar(
                            currentStep: _currentStep, totalSteps: 2),
                      ),
                      const SizedBox(width: 12),
                      _LanguageToggle(isZh: isZh),
                    ],
                  ),
                ),

                // ── Pages ──
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(l),
                      _buildStep2(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Account Details ─────────────────────────────────────────────────

  Widget _buildStep1(AppLocalizations l) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 90,
              height: 90,
              child: Image.asset(
                'assets/logo/vpnlogo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(l.signUpTitle,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(l.signUpSubtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 32),
          _buildField(
              controller: _nameController,
              hint: l.nameHint,
              icon: Icons.person_outlined),
          const SizedBox(height: 14),
          _buildField(
              controller: _emailController,
              hint: l.emailHint,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: l.passwordHint,
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
              suffixIcon: GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white54,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFF1B2160),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isRegistering ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1C2363),
                disabledBackgroundColor: Colors.white38,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isRegistering
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Color(0xFF1C2363)),
                    )
                  : const Text('Continue →',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1B2160),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ── Step 2: Plan Selection ──────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Choose Your Plan',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'Select a plan to get started. You can change it anytime.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
        Expanded(
          child: _loadingPlans
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: 3,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _shimmerBox(height: 130, radius: 18),
                  ),
                )
              : _plans.isEmpty
                  ? _buildNoPlans()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      itemCount: _plans.length,
                      itemBuilder: (_, i) => _buildPlanTile(_plans[i], i),
                    ),
        ),
        // ── Sticky bottom buttons ──
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2363),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _subscribing ? null : _handleFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C3BFF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF5C3BFF).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _subscribing
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Get Started 🚀',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _subscribing ? null : _goToApp,
                child: const Text(
                  'Skip — use Free plan for now',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTile(Map<String, dynamic> plan, int index) {
    final id = plan['id']?.toString() ?? '';
    final name = plan['name']?.toString() ?? 'Plan';
    final price = double.tryParse(plan['price']?.toString() ?? '0') ?? 0;
    int _safeInt(dynamic v, int fb) =>
        v == null ? fb : (v is int ? v : int.tryParse(v.toString()) ?? fb);
    final days = _safeInt(plan['duration_days'], 30);
    final devices = _safeInt(plan['max_devices'], 1);
    final description = plan['description']?.toString();
    final String billingLabel = days >= 365
        ? '/year'
        : days >= 28
            ? '/month'
            : ' for $days days';
    final bool isSelected = _selectedPlanId == id;
    final bool isRecommended = index == _recommendedIndex();

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [const Color(0xFF5C3BFF), const Color(0xFF3B20CC)]
                : [const Color(0xFF1B2160), const Color(0xFF1F2570)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8A6FFF)
                : isRecommended
                    ? const Color(0xFF5C3BFF).withOpacity(0.5)
                    : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5C3BFF).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF00E5A0)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00E5A0)
                          : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 14),
                // Plan info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_planIcon(name),
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(description,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [
                          _chip('$devices device${devices > 1 ? "s" : ""}'),
                          _chip('$days-day plan'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price == 0
                          ? 'Free'
                          : '\$${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: price == 0
                            ? const Color(0xFF00E5A0)
                            : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (price > 0)
                      Text(billingLabel,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ],
            ),
            // Recommended badge
            if (isRecommended)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5A0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'BEST',
                    style: TextStyle(
                      color: Color(0xFF003A28),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 10)),
    );
  }

  Widget _buildNoPlans() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: Colors.white24, size: 56),
          const SizedBox(height: 16),
          const Text('Could not load plans',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _fetchPlans,
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF5C3BFF)),
            label: const Text('Retry',
                style: TextStyle(color: Color(0xFF5C3BFF))),
          ),
        ],
      ),
    );
  }
}

// ── Step progress bar ──────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepProgressBar(
      {required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF5C3BFF)
                  : Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ── Language toggle ────────────────────────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  final bool isZh;
  const _LanguageToggle({required this.isZh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        MyApp.of(context)
            .setLocale(isZh ? const Locale('en') : const Locale('zh'));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2160),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF5C3BFF).withOpacity(0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(isZh ? '中' : 'EN',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          const Icon(Icons.language_rounded, color: Colors.white70, size: 16),
        ]),
      ),
    );
  }
}
