import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vpn_app/l10n/app_localizations.dart';
import 'package:vpn_app/main.dart';
import 'package:vpn_app/models/vpn_server_model.dart';
import 'package:vpn_app/utilities/vpn_service.dart';
import 'package:vpn_app/services/notification_service.dart';
import 'package:vpn_app/services/auth_service.dart';
import 'package:vpn_app/screens/welcomeScreen.dart';
import 'package:vpn_app/screens/subscribeScreen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with TickerProviderStateMixin {
  // --- VPN state (driven by real VpnService) ---
  bool _isConnected = false;
  bool _isConnecting = false;
  VpnServerModel _selectedServer = _servers.first;

  // --- Animation controllers ---
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  late Animation<double> _pulse1;
  late Animation<double> _pulse2;
  late Animation<double> _pulse3;

  // --- User / subscription state ---
  String? _userName;
  String? _userEmail;
  String _currentPlanName = 'Free Plan';

  // --- Server list (countryKey is used for localization lookup) ---
  static const List<VpnServerModel> _servers = [
    // VpnServerModel(
    //   country: 'United States',
    //   countryKey: 'countryUnitedStates',
    //   flag: '🇺🇸',
    //   ping: '12 ms',
    //   configAssetPath: 'assets/vpn_configs/us.ovpn',
    // ),
    // VpnServerModel(
    //   country: 'United Kingdom',
    //   countryKey: 'countryUnitedKingdom',
    //   flag: '🇬🇧',
    //   ping: '28 ms',
    //   configAssetPath: 'assets/vpn_configs/uk.ovpn',
    // ),
    // VpnServerModel(
    //   country: 'Germany',
    //   countryKey: 'countryGermany',
    //   flag: '🇩🇪',
    //   ping: '35 ms',
    //   configAssetPath: 'assets/vpn_configs/de.ovpn',
    // ),
    // VpnServerModel(
    //   country: 'Japan',
    //   countryKey: 'countryJapan',
    //   flag: '🇯🇵',
    //   ping: '42 ms',
    //   configAssetPath: 'assets/vpn_configs/jp.ovpn',
    // ),
    // VpnServerModel(
    //   country: 'Singapore',
    //   countryKey: 'countrySingapore',
    //   flag: '🇸🇬',
    //   ping: '55 ms',
    //   configAssetPath: 'assets/vpn_configs/sg.ovpn',
    // ),
    // VpnServerModel(
    //   country: 'Australia',
    //   countryKey: 'countryAustralia',
    //   flag: '🇦🇺',
    //   ping: '78 ms',
    //   configAssetPath: 'assets/vpn_configs/au.ovpn',
    // ),
    // VpnServerModel(
    //   country: 'Canada',
    //   countryKey: 'countryCanada',
    //   flag: '🇨🇦',
    //   ping: '18 ms',
    //   configAssetPath: 'assets/vpn_configs/ca.ovpn',
    // ),
    // VpnServerModel(
    //   country: 'Netherlands',
    //   countryKey: 'countryNetherlands',
    //   flag: '🇳🇱',
    //   ping: '31 ms',
    //   configAssetPath: 'assets/vpn_configs/nl.ovpn',
    // ),
    VpnServerModel(
      country: 'Malaysia',
      countryKey: 'adminServer',
      flag: '🌐',
      ping: '45 ms',
      configAssetPath: 'assets/vpn_configs/profile-userlocked-admin.ovpn',
      username: 'admin',
      password: 'RainbowB321@', // Supply password if required by your AS
    ),
  ];

  // --- Stats ---
  String _downloadSpeed = '0.0';
  String _uploadSpeed = '0.0';
  String _duration = '00:00:00';
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();

    // ── Pulse rings ──
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulse1 = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulse2 = Tween<double>(begin: 0.75, end: 1.25).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeInOut),
      ),
    );
    _pulse3 = Tween<double>(begin: 0.65, end: 1.35).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    // ── Outer ring rotation ──
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // ── Initialize real OpenVPN service ──
    _initVpnService();

    // ── Request notification permission (Android 13+) ──
    _requestNotificationPermission();

    // ── Load user info and current subscription ──
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    _userName = AuthService.currentUserName;
    _userEmail = AuthService.currentUserEmail;
    try {
      final result = await AuthService.getCurrentSubscription();
      final sub = result['subscription'] as Map<String, dynamic>?;
      if (sub != null) {
        final plan = sub['plan'] as Map<String, dynamic>?;
        final planName = plan?['name'] as String? ??
            sub['plan_name'] as String?;
        if (mounted && planName != null) {
          setState(() => _currentPlanName = planName);
        }
      } else {
        if (mounted) setState(() => _currentPlanName = 'Free Plan');
      }
    } catch (_) {
      // keep default 'Free Plan'
    }
    if (mounted) setState(() {
      // trigger rebuild with name/email
    });
  }

  void _initVpnService() {
    final vpn = VpnService.instance;
    vpn.initialize();

    vpn.onStageChanged = (VPNStage? stage) {
      if (!mounted) return;
      setState(() {
        _isConnected = vpn.isConnected;
        _isConnecting = vpn.isConnecting;

        // Reset stats on disconnect
        if (stage == VPNStage.disconnected ||
            stage == VPNStage.denied ||
            stage == VPNStage.error) {
          _elapsedSeconds = 0;
          _downloadSpeed = '0.0';
          _uploadSpeed = '0.0';
          _duration = '00:00:00';

          if (stage == VPNStage.disconnected) {
            NotificationService.showVpnNotification(
              title: 'VPN Disconnected',
              body: 'You are no longer connected to ${_selectedServer.country}',
              isConnected: false,
            );
          }
        }

        // Start timer when connected
        if (stage == VPNStage.connected) {
          _startTimer();
          NotificationService.showVpnNotification(
            title: 'VPN Connected',
            body:
                'You are now securely connected to ${_selectedServer.country}',
            isConnected: true,
          );
        }

        // Show error snackbar
        if (stage == VPNStage.error || stage == VPNStage.denied) {
          final l = AppLocalizations.of(context);
          _showError(
            stage == VPNStage.denied
                ? l.errorVpnPermissionDenied
                : l.errorVpnConnection,
          );
        }
      });
    };

    vpn.onStatusChanged = (VpnStatus? status) {
      if (!mounted || status == null) return;

      setState(() {
        // Convert bytes/s to MB/s for display
        final rxBytes = double.tryParse(status.byteIn ?? '0') ?? 0;
        final txBytes = double.tryParse(status.byteOut ?? '0') ?? 0;
        _downloadSpeed = (rxBytes / 1024 / 1024).toStringAsFixed(1);
        _uploadSpeed = (txBytes / 1024 / 1024).toStringAsFixed(1);
      });
    };
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await Permission.notification.isGranted;
    if (!granted) {
      await Permission.notification.request();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    // Clear service callbacks to prevent calling setState after dispose
    VpnService.instance.onStageChanged = null;
    VpnService.instance.onStatusChanged = null;
    super.dispose();
  }

  // ---- Toggle connect ----
  void _toggleConnection() async {
    if (_isConnecting) return;

    final vpn = VpnService.instance;

    if (_isConnected) {
      // Disconnect
      setState(() => _isConnecting = true);
      vpn.disconnect();
    } else {
      // Connect
      setState(() => _isConnecting = true);
      try {
        await vpn.connect(_selectedServer);
      } catch (e) {
        if (mounted) {
          setState(() => _isConnecting = false);
          _showError('${AppLocalizations.of(context).errorLoadConfig}$e');
        }
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF3A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startTimer() {
    _elapsedSeconds = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isConnected) return false;
      setState(() {
        _elapsedSeconds++;
        final h = _elapsedSeconds ~/ 3600;
        final m = (_elapsedSeconds % 3600) ~/ 60;
        final s = _elapsedSeconds % 60;
        _duration =
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      });
      return _isConnected;
    });
  }

  // ---- Server picker ----
  void _showServerPicker() {
    // Don't allow changing server while connected/connecting
    if (_isConnected || _isConnecting) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ServerSheet(
        servers: _servers,
        selected: _selectedServer.country,
        onSelect: (server) {
          setState(() => _selectedServer = server);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    const Color connectedColor = Color(0xFF00E5A0);
    const Color connectingColor = Color(0xFFFFB800);
    const Color idleColor = Colors.white;

    Color activeColor = _isConnected
        ? connectedColor
        : _isConnecting
        ? connectingColor
        : idleColor;

    // Resolve status label from localizations
    final vpnStage = VpnService.instance.stage;
    final String statusLabel;
    switch (vpnStage) {
      case VPNStage.connected:
        statusLabel = l.statusConnected;
        break;
      case VPNStage.connecting:
      case VPNStage.prepare:
        statusLabel = l.statusConnecting;
        break;
      case VPNStage.authenticating:
      case VPNStage.authentication:
        statusLabel = l.statusAuthenticating;
        break;
      case VPNStage.disconnecting:
        statusLabel = l.statusDisconnecting;
        break;
      case VPNStage.denied:
        statusLabel = l.statusPermissionDenied;
        break;
      case VPNStage.error:
        statusLabel = l.statusError;
        break;
      default:
        statusLabel = l.statusNotConnected;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1C2363),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1B2160),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5C3BFF), Color(0xFF1B2160)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(color: Colors.white38, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName ?? _userEmail ?? 'VPN User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _currentPlanName,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: Color(0xFF00E5A0),
              ),
              title: const Text(
                'Profile',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_rounded, color: Color(0xFFFFB800)),
              title: const Text(
                'Subscribe',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Upgrade your plan',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscribeScreen()),
                );
                // Refresh plan badge when returning from subscription screen
                if (mounted) _loadSubscription();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.settings_outlined,
                color: Color(0xFF5C3BFF),
              ),
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white12, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white54),
              title: const Text('About', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.white54),
              title: const Text(
                'Help & Support',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Colors.white54),
              title: const Text(
                'Share App',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white12, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFFF5C5C),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFFF5C5C),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context); // close drawer first
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (_) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ── Decorative background shapes ──
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
              child: Container(
                width: 180,
                height: 300,
                color: const Color(0xFF182056),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Column(
              children: [
                // ── App Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (drawerContext) => IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () =>
                              Scaffold.of(drawerContext).openDrawer(),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B2160),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.flash_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.appTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      _ConnectLanguageToggle(isZh: isZh),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // ── Status label ──
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            statusLabel,
                            key: ValueKey(statusLabel),
                            style: TextStyle(
                              color: activeColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Server Selector Button ──
                        GestureDetector(
                          onTap: _showServerPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedServer.flag,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedServer.country,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Power button with animated rings ──
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer rotating dashed ring
                              AnimatedBuilder(
                                animation: _rotateController,
                                builder: (_, __) => Transform.rotate(
                                  angle: _rotateController.value * 2 * math.pi,
                                  child: CustomPaint(
                                    size: const Size(240, 240),
                                    painter: _DashedCirclePainter(
                                      color: activeColor.withOpacity(0.25),
                                    ),
                                  ),
                                ),
                              ),

                              // Pulse rings (only when connecting or connected)
                              if (_isConnected || _isConnecting) ...[
                                AnimatedBuilder(
                                  animation: _pulse3,
                                  builder: (_, __) => Transform.scale(
                                    scale: _pulse3.value,
                                    child: Container(
                                      width: 196,
                                      height: 196,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: activeColor.withOpacity(0.08),
                                          width: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _pulse2,
                                  builder: (_, __) => Transform.scale(
                                    scale: _pulse2.value,
                                    child: Container(
                                      width: 172,
                                      height: 172,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: activeColor.withOpacity(0.15),
                                          width: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _pulse1,
                                  builder: (_, __) => Transform.scale(
                                    scale: _pulse1.value,
                                    child: Container(
                                      width: 148,
                                      height: 148,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: activeColor.withOpacity(0.25),
                                          width: 6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              // Core button
                              GestureDetector(
                                onTap: _toggleConnection,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: _isConnected
                                          ? [
                                              const Color(
                                                0xFF00E5A0,
                                              ).withOpacity(0.9),
                                              const Color(0xFF007A56),
                                            ]
                                          : _isConnecting
                                          ? [
                                              const Color(
                                                0xFFFFB800,
                                              ).withOpacity(0.9),
                                              const Color(0xFF7A5700),
                                            ]
                                          : [
                                              const Color(0xFF5C3BFF),
                                              const Color(0xFF1B2160),
                                            ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: activeColor.withOpacity(0.35),
                                        blurRadius: 30,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: _isConnecting
                                      ? const _SpinnerIcon()
                                      : const Icon(
                                          Icons.power_settings_new_rounded,
                                          color: Colors.white,
                                          size: 52,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Duration (when connected) ──
                        AnimatedOpacity(
                          opacity: _isConnected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            _duration,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              letterSpacing: 2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Stats row ──
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.arrow_downward_rounded,
                                iconColor: const Color(0xFF00E5A0),
                                label: l.download,
                                value: '$_downloadSpeed MB/s',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.arrow_upward_rounded,
                                iconColor: const Color(0xFF5C3BFF),
                                label: l.upload,
                                value: '$_uploadSpeed MB/s',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.timer_outlined,
                                iconColor: const Color(0xFFFFB800),
                                label: l.duration,
                                value: _duration,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Features row ──
                        Row(
                          children: [
                            Expanded(
                              child: _FeatureTile(
                                icon: Icons.security_rounded,
                                label: l.noLogPolicy,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FeatureTile(
                                icon: Icons.speed_rounded,
                                label: l.ultraFast,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FeatureTile(
                                icon: Icons.lock_rounded,
                                label: l.aes256,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Bottom nav ──
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dashed circle painter (outer ring)
// ─────────────────────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashCount = 36;
    const dashAngle = math.pi * 2 / dashCount;
    const gapRatio = 0.45;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapRatio);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

// ─────────────────────────────────────────────
// Spinner icon (shown while connecting)
// ─────────────────────────────────────────────
class _SpinnerIcon extends StatefulWidget {
  const _SpinnerIcon();

  @override
  State<_SpinnerIcon> createState() => _SpinnerIconState();
}

class _SpinnerIconState extends State<_SpinnerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 44),
    );
  }
}

// ─────────────────────────────────────────────
// Stat card
// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2160),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5C3BFF).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + label stacked vertically to avoid horizontal overflow
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────
// Feature tile
// ─────────────────────────────────────────────
class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2160),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5C3BFF).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF5C3BFF), size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom nav bar
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// Server picker bottom sheet
// ─────────────────────────────────────────────
class _ServerSheet extends StatelessWidget {
  final List<VpnServerModel> servers;
  final String selected;
  final void Function(VpnServerModel server) onSelect;

  const _ServerSheet({
    required this.servers,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF1C2363),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).selectServer,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: servers.length,
              itemBuilder: (_, i) {
                final s = servers[i];
                final isSelected = s.country == selected;
                return GestureDetector(
                  onTap: () {
                    onSelect(s);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF5C3BFF).withOpacity(0.25)
                          : const Color(0xFF1B2160),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF5C3BFF)
                            : const Color(0xFF5C3BFF).withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(s.flag, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            s.localizedCountry(AppLocalizations.of(context)),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        // Ping badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5A0).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.ping,
                            style: const TextStyle(
                              color: Color(0xFF00E5A0),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF5C3BFF),
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Language toggle (connect screen)
// ─────────────────────────────────────────────
class _ConnectLanguageToggle extends StatelessWidget {
  final bool isZh;
  const _ConnectLanguageToggle({required this.isZh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        MyApp.of(
          context,
        ).setLocale(isZh ? const Locale('en') : const Locale('zh'));
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2160),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF5C3BFF).withOpacity(0.4)),
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
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.language_rounded, color: Colors.white70, size: 15),
          ],
        ),
      ),
    );
  }
}
