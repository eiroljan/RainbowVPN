import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vpn_app/main.dart';
import 'package:vpn_app/screens/subscribeScreen.dart';
import 'package:vpn_app/services/auth_service.dart';
import 'package:vpn_app/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Settings state ──────────────────────────────────────────────────────────
  bool _autoConnect        = false;
  bool _killSwitch         = false;
  String _protocol         = 'UDP';
  bool _connNotifications  = true;
  bool _dataAlerts         = true;
  String _language         = 'en';

  bool _loading = true;

  // ── Account state ───────────────────────────────────────────────────────────
  String? _email;
  String? _planName;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final settings = await SettingsService.load();
    final sub = await AuthService.getCurrentSubscription();
    final subMap = sub['subscription'] as Map<String, dynamic>?;
    final plan = subMap?['plan'] as Map<String, dynamic>?;

    if (!mounted) return;
    setState(() {
      _autoConnect        = settings.autoConnect;
      _killSwitch         = settings.killSwitch;
      _protocol           = settings.protocol;
      _connNotifications  = settings.connNotifications;
      _dataAlerts         = settings.dataAlerts;
      _language           = settings.language;
      _email              = AuthService.currentUserEmail;
      _planName           = plan?['name'] as String? ??
                            subMap?['plan_name'] as String? ??
                            'Free Plan';
      _loading            = false;
    });
  }

  // ── Persistence helpers ──────────────────────────────────────────────────────

  Future<void> _toggle(String key, bool value) =>
      SettingsService.setBool(key, value);

  Future<void> _setString(String key, String value) =>
      SettingsService.setString(key, value);

  // ── UI helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool success = false}) {
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

  // ── Protocol picker ──────────────────────────────────────────────────────────

  void _showProtocolPicker() {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1B2160),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text(
              'VPN Protocol',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'UDP is faster. TCP is more reliable on restricted networks.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            for (final proto in ['UDP', 'TCP'])
              _ProtocolTile(
                label: proto,
                subtitle: proto == 'UDP'
                    ? 'Faster speeds, lower latency'
                    : 'More reliable on firewalled networks',
                selected: _protocol == proto,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _protocol = proto);
                  _setString(SettingsService.protocolKey, proto);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Language switcher ────────────────────────────────────────────────────────

  void _showLanguagePicker() {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1B2160),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Language',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            for (final entry in [
              ('en', '🇬🇧', 'English'),
              ('zh', '🇨🇳', '中文 (Chinese)'),
            ])
              _ProtocolTile(
                label: '${entry.$2}  ${entry.$3}',
                subtitle: entry.$1 == 'en' ? 'English' : '简体中文',
                selected: _language == entry.$1,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _language = entry.$1);
                  _setString(SettingsService.languageKey, entry.$1);
                  MyApp.of(context).setLocale(Locale(entry.$1));
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Change password ──────────────────────────────────────────────────────────

  void _showChangePassword() {
    final newCtrl      = TextEditingController();
    final confirmCtrl  = TextEditingController();
    bool obscureNew     = true;
    bool obscureConfirm = true;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1B2160),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Change Password',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _PwField(
                    ctrl: newCtrl,
                    label: 'New Password',
                    obscure: obscureNew,
                    onToggle: () =>
                        setSheetState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 12),
                  _PwField(
                    ctrl: confirmCtrl,
                    label: 'Confirm New Password',
                    obscure: obscureConfirm,
                    onToggle: () => setSheetState(
                        () => obscureConfirm = !obscureConfirm),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final newPw = newCtrl.text.trim();
                              final confirm = confirmCtrl.text.trim();
                              if (newPw.isEmpty || confirm.isEmpty) {
                                _showSnack('Please fill all fields');
                                return;
                              }
                              if (newPw != confirm) {
                                _showSnack('Passwords do not match');
                                return;
                              }
                              if (newPw.length < 6) {
                                _showSnack(
                                    'Password must be at least 6 characters');
                                return;
                              }
                              setSheetState(() => saving = true);
                              try {
                                await Supabase.instance.client.auth
                                    .updateUser(
                                  UserAttributes(password: newPw),
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  _showSnack(
                                      '✅ Password updated successfully',
                                      success: true);
                                }
                              } catch (e) {
                                setSheetState(() => saving = false);
                                _showSnack('Error: ${e.toString()}');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C3BFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Update Password',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2363),
      body: Stack(
        children: [
          // ── Decorative background shapes ──
          Positioned(
            top: -100, left: -80,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                  width: 220, height: 450,
                  color: const Color(0xFF5C3BFF)),
            ),
          ),
          Positioned(
            top: -50, right: -70,
            child: Transform.rotate(
              angle: 0.1,
              child: Container(
                  width: 180, height: 300,
                  color: const Color(0xFF6A40FF)),
            ),
          ),
          Positioned(
            bottom: -100, right: -50,
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                  width: 180, height: 300,
                  color: const Color(0xFF182056)),
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
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Customize your VPN experience',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Body ──
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF5C3BFF)))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          children: [

                            // ─── Connection ─────────────────────────────────
                            _SectionHeader(
                                icon: Icons.lan_rounded,
                                label: 'Connection'),

                            _SettingsCard(children: [
                              _ToggleRow(
                                icon: Icons.flash_on_rounded,
                                iconColor: const Color(0xFF00E5A0),
                                title: 'Auto-connect on Launch',
                                subtitle:
                                    'Automatically connect VPN when app opens',
                                value: _autoConnect,
                                onChanged: (v) {
                                  setState(() => _autoConnect = v);
                                  _toggle(SettingsService.autoConnectKey, v);
                                },
                              ),
                              _Divider(),
                              _ToggleRow(
                                icon: Icons.security_rounded,
                                iconColor: const Color(0xFFFF5C5C),
                                title: 'Kill Switch',
                                subtitle:
                                    'Block internet if VPN connection drops',
                                value: _killSwitch,
                                onChanged: (v) {
                                  setState(() => _killSwitch = v);
                                  _toggle(SettingsService.killSwitchKey, v);
                                },
                              ),
                              _Divider(),
                              _TappableRow(
                                icon: Icons.settings_ethernet_rounded,
                                iconColor: const Color(0xFF5C3BFF),
                                title: 'VPN Protocol',
                                subtitle: _protocol,
                                onTap: _showProtocolPicker,
                              ),
                            ]),

                            const SizedBox(height: 20),

                            // ─── Appearance ──────────────────────────────────
                            _SectionHeader(
                                icon: Icons.palette_rounded,
                                label: 'Appearance'),

                            _SettingsCard(children: [
                              _TappableRow(
                                icon: Icons.language_rounded,
                                iconColor: const Color(0xFFFFB800),
                                title: 'Language',
                                subtitle: _language == 'zh'
                                    ? '中文 (Chinese)'
                                    : 'English',
                                onTap: _showLanguagePicker,
                              ),
                            ]),

                            const SizedBox(height: 20),

                            // ─── Notifications ───────────────────────────────
                            _SectionHeader(
                                icon: Icons.notifications_rounded,
                                label: 'Notifications'),

                            _SettingsCard(children: [
                              _ToggleRow(
                                icon: Icons.wifi_rounded,
                                iconColor: const Color(0xFF00E5A0),
                                title: 'Connection Alerts',
                                subtitle:
                                    'Notify when VPN connects or disconnects',
                                value: _connNotifications,
                                onChanged: (v) {
                                  setState(() => _connNotifications = v);
                                  _toggle(
                                      SettingsService.connNotificationsKey,
                                      v);
                                },
                              ),
                              _Divider(),
                              _ToggleRow(
                                icon: Icons.data_usage_rounded,
                                iconColor: const Color(0xFF5C3BFF),
                                title: 'Data Usage Alerts',
                                subtitle:
                                    'Alert when session data exceeds 1 GB',
                                value: _dataAlerts,
                                onChanged: (v) {
                                  setState(() => _dataAlerts = v);
                                  _toggle(SettingsService.dataAlertsKey, v);
                                },
                              ),
                            ]),

                            const SizedBox(height: 20),

                            // ─── Account ─────────────────────────────────────
                            _SectionHeader(
                                icon: Icons.person_rounded,
                                label: 'Account'),

                            _SettingsCard(children: [
                              _InfoRow(
                                icon: Icons.email_outlined,
                                iconColor: Colors.white54,
                                title: 'Email',
                                value: _email ?? '—',
                              ),
                              _Divider(),
                              _InfoRow(
                                icon: Icons.workspace_premium_rounded,
                                iconColor: const Color(0xFFFFB800),
                                title: 'Current Plan',
                                value: _planName ?? 'Free Plan',
                              ),
                              _Divider(),
                              _TappableRow(
                                icon: Icons.star_rounded,
                                iconColor: const Color(0xFFFFB800),
                                title: 'Manage Subscription',
                                subtitle: 'Upgrade or change your plan',
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const SubscribeScreen()),
                                  );
                                  // Refresh plan name on return
                                  if (mounted) _loadAll();
                                },
                              ),
                              _Divider(),
                              _TappableRow(
                                icon: Icons.lock_outline_rounded,
                                iconColor: const Color(0xFF5C3BFF),
                                title: 'Change Password',
                                subtitle: 'Update your account password',
                                onTap: _showChangePassword,
                              ),
                            ]),

                            const SizedBox(height: 20),

                            // ─── App info ────────────────────────────────────
                            _SettingsCard(children: [
                              _InfoRow(
                                icon: Icons.info_outline_rounded,
                                iconColor: Colors.white38,
                                title: 'Version',
                                value: '1.0.0',
                              ),
                            ]),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
        color: Colors.white10,
        height: 1,
        indent: 56,
      );
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _IconBadge(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF5C3BFF),
            activeTrackColor: const Color(0xFF5C3BFF).withValues(alpha: 0.35),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}

class _TappableRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _TappableRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconBadge(icon: icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 22),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _IconBadge(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _ProtocolTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ProtocolTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF5C3BFF).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF8A6FFF).withValues(alpha: 0.6)
                : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF5C3BFF), size: 22)
            else
              const Icon(Icons.radio_button_unchecked_rounded,
                  color: Colors.white24, size: 22),
          ],
        ),
      ),
    );
  }
}

class _PwField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _PwField({
    required this.ctrl,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFF8A6FFF),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: Colors.white38, size: 18),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: Colors.white38,
            size: 18,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF7A5FFF), width: 1.5),
        ),
      ),
    );
  }
}
