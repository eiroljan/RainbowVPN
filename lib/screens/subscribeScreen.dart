import 'package:flutter/material.dart';
import 'package:vpn_app/services/auth_service.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen>
    with SingleTickerProviderStateMixin {
  bool _loadingPlans = true;
  bool _loadingSubscription = true;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _currentSubscription;
  String? _processingPlanId;   // store as String for safe comparison
  bool _cancellingSubscription = false;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        AuthService.getPlans(),
        AuthService.getCurrentSubscription(),
      ]);

      final plansData = results[0];
      final subData = results[1];

      if (mounted) {
        setState(() {
          _plans = List<Map<String, dynamic>>.from(plansData['plans'] ?? []);
          _currentSubscription =
              subData['subscription'] as Map<String, dynamic>?;
          _loadingPlans = false;
          _loadingSubscription = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingPlans = false;
          _loadingSubscription = false;
        });
      }
    }
  }

  Future<void> _subscribe(dynamic planId) async {
    final idStr = planId.toString();
    setState(() => _processingPlanId = idStr);
    try {
      final parsedId = int.tryParse(idStr) ?? 0;
      final result = await AuthService.subscribe(parsedId);
      if (!mounted) return;
      if (result.containsKey('subscription')) {
        setState(() {
          _currentSubscription =
              result['subscription'] as Map<String, dynamic>;
        });
        _showSnack('✅ ${result['message'] ?? 'Subscribed successfully!'}',
            success: true);
      } else {
        _showSnack(result['message'] ?? 'Subscription failed.');
      }
    } catch (e) {
      if (mounted) _showSnack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _processingPlanId = null);
    }
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B2160),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Subscription',
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to cancel your current subscription?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Plan',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancel Plan',
              style: TextStyle(
                  color: Color(0xFFFF5C5C),
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _cancellingSubscription = true);
    try {
      final result = await AuthService.cancelSubscription();
      if (!mounted) return;
      if (result.containsKey('subscription')) {
        setState(() => _currentSubscription = null);
        _showSnack(result['message'] ?? 'Subscription cancelled.',
            success: true);
      } else {
        _showSnack(result['message'] ?? 'Failed to cancel.');
      }
    } catch (_) {
      if (mounted) _showSnack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _cancellingSubscription = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor:
            success ? const Color(0xFF1A3A2A) : const Color(0xFF3A1A1A),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _planIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('free')) return '🆓';
    if (n.contains('basic')) return '⚡';
    if (n.contains('pro') || n.contains('premium')) return '👑';
    if (n.contains('ultimate') || n.contains('max')) return '🚀';
    return '✨';
  }

  bool _isCurrentPlan(Map<String, dynamic> plan) {
    if (_currentSubscription == null) return false;
    final subPlan = _currentSubscription!['plan'];
    if (subPlan == null) {
      // Fallback: compare plan_id directly on subscription
      final subPlanId = _currentSubscription!['plan_id'];
      return subPlanId?.toString() == plan['id']?.toString();
    }
    return subPlan['id']?.toString() == plan['id']?.toString();
  }

  int _recommendedIndex() {
    if (_plans.isEmpty) return 0;
    // Pick second-from-last (best-value middle plan) if more than 1
    if (_plans.length > 1) return _plans.length - 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2363),
      body: Stack(
        children: [
          // ── Decorative background shapes ──
          Positioned(
            top: -100,
            left: -80,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                  width: 220, height: 450, color: const Color(0xFF5C3BFF)),
            ),
          ),
          Positioned(
            top: -50,
            right: -70,
            child: Transform.rotate(
              angle: 0.1,
              child: Container(
                  width: 180, height: 300, color: const Color(0xFF6A40FF)),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                  width: 180, height: 300, color: const Color(0xFF182056)),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 22),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Your Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Upgrade for premium access',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Current subscription banner ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCurrentSubBanner(),
                ),

                const SizedBox(height: 16),

                // ── Plans ──
                Expanded(
                  child: _loadingPlans
                      ? _buildShimmerList()
                      : _plans.isEmpty
                          ? _buildEmpty()
                          : _buildPlanList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── Current subscription banner ───────────────────────────

  Widget _buildCurrentSubBanner() {
    if (_loadingSubscription) {
      return _shimmerBox(height: 72, radius: 16);
    }

    final sub = _currentSubscription;
    if (sub == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Colors.white54, size: 20),
            SizedBox(width: 10),
            Text('No active subscription',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      );
    }

    final plan = sub['plan'] as Map<String, dynamic>?;
    final planName = plan?['name'] ?? 'Plan';
    final expiresAt = sub['expires_at'] as String?;
    final expiresLabel =
        expiresAt != null ? 'Expires ${_formatDate(expiresAt)}' : 'Active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C77A), Color(0xFF007A4C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C77A).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active — $planName',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                Text(expiresLabel,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          _cancellingSubscription
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : GestureDetector(
                  onTap: _cancelSubscription,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ───────────────────────────── Plan list ────────────────────────────────────

  Widget _buildPlanList() {
    final recommended = _recommendedIndex();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: _plans.length,
      itemBuilder: (_, i) => _PlanCard(
        plan: _plans[i],
        icon: _planIcon(_plans[i]['name']?.toString() ?? ''),
        isRecommended: i == recommended,
        isCurrentPlan: _isCurrentPlan(_plans[i]),
        isProcessing: _processingPlanId == _plans[i]['id']?.toString(),
        onSubscribe: () => _subscribe(_plans[i]['id']),
      ),
    );
  }

  // ───────────────────────────── Shimmer ──────────────────────────────────────

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: 3,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _shimmerBox(height: 190, radius: 20),
      ),
    );
  }

  Widget _shimmerBox({required double height, double radius = 12}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) {
        return Container(
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
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: Colors.white24, size: 60),
          const SizedBox(height: 16),
          const Text('No plans available',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _loadingPlans = true;
                _loadingSubscription = true;
              });
              _loadData();
            },
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF5C3BFF)),
            label: const Text('Retry',
                style: TextStyle(color: Color(0xFF5C3BFF))),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── Utility ──────────────────────────────────────

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual plan card
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String icon;
  final bool isRecommended;
  final bool isCurrentPlan;
  final bool isProcessing;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.icon,
    required this.isRecommended,
    required this.isCurrentPlan,
    required this.isProcessing,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final name = plan['name']?.toString() ?? 'Plan';
    final price = double.tryParse(plan['price']?.toString() ?? '0') ?? 0;
    // Safe int parsing — Supabase may return these as int or String
    int _parseInt(dynamic v, int fallback) =>
        v == null ? fallback : (v is int ? v : int.tryParse(v.toString()) ?? fallback);
    final duration = _parseInt(plan['duration_days'], 30);
    final description = plan['description']?.toString();
    final bandwidthRaw = plan['bandwidth_gb'];
    final bandwidth = bandwidthRaw == null ? null : _parseInt(bandwidthRaw, 0);
    final maxDevices = _parseInt(plan['max_devices'], 1);

    final String billingLabel;
    if (duration >= 365) {
      billingLabel = 'per year';
    } else if (duration >= 28) {
      billingLabel = 'per month';
    } else {
      billingLabel = 'for $duration days';
    }

    final features = <String>[
      '$maxDevices device${maxDevices > 1 ? 's' : ''}',
      bandwidth != null ? '${bandwidth}GB bandwidth' : 'Unlimited bandwidth',
      '$duration-day plan',
    ];
    if (description != null && description.isNotEmpty) {
      features.insert(0, description);
    }

    final List<Color> gradient;
    if (isCurrentPlan) {
      gradient = [const Color(0xFF006B42), const Color(0xFF004D2E)];
    } else if (isRecommended) {
      gradient = [const Color(0xFF5C3BFF), const Color(0xFF3B20CC)];
    } else {
      gradient = [const Color(0xFF1B2160), const Color(0xFF232B7A)];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isRecommended && !isCurrentPlan
                    ? const Color(0xFF8A6FFF).withOpacity(0.6)
                    : Colors.white12,
                width: isRecommended ? 1.5 : 1,
              ),
              boxShadow: isRecommended
                  ? [
                      BoxShadow(
                        color:
                            const Color(0xFF5C3BFF).withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Plan header ──
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                              if (price > 0) ...[
                                const SizedBox(width: 4),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    billingLabel,
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),

                // ── Features ──
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF00E5A0),
                            size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(f,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── CTA ──
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isProcessing || isCurrentPlan
                        ? null
                        : onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? Colors.white.withOpacity(0.15)
                          : isRecommended
                              ? Colors.white
                              : Colors.white.withOpacity(0.12),
                      foregroundColor:
                          isRecommended && !isCurrentPlan
                              ? const Color(0xFF3B20CC)
                              : Colors.white,
                      disabledBackgroundColor:
                          Colors.white.withOpacity(0.1),
                      disabledForegroundColor: Colors.white54,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : Text(
                            isCurrentPlan
                                ? '✓ Current Plan'
                                : 'Get Started',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // ── Recommended badge ──
          if (isRecommended && !isCurrentPlan)
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5A0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    color: Color(0xFF003A28),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
