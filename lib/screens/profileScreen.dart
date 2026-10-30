import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vpn_app/l10n/app_localizations.dart';
import 'package:vpn_app/services/auth_service.dart';
import 'package:vpn_app/screens/subscribeScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  String? _email;
  String? _planName;
  String _displayName = '';
  bool _loading = true;
  bool _savingName = false;

  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAccountInfo();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadAccountInfo() async {
    final sub = await AuthService.getCurrentSubscription();
    final subMap = sub['subscription'] as Map<String, dynamic>?;
    final plan = subMap?['plan'] as Map<String, dynamic>?;

    if (!mounted) return;
    final name = AuthService.currentUserName ?? '';
    setState(() {
      _email = AuthService.currentUserEmail;
      _planName = plan?['name'] as String? ??
          subMap?['plan_name'] as String? ??
          'Free Plan';
      _displayName = name;
      _nameCtrl.text = name;
      _loading = false;
    });
  }

  // ── Snack helper ───────────────────────────────────────────────────────────

  void _snack(String msg, {bool success = false}) {
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

  // ── Save display name ──────────────────────────────────────────────────────

  Future<void> _saveName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      _snack('Name cannot be empty.');
      return;
    }
    setState(() => _savingName = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'name': newName}),
      );
      setState(() {
        _displayName = newName;
        _savingName = false;
      });
      _snack('Name updated!', success: true);
    } catch (e) {
      setState(() => _savingName = false);
      _snack('Error: ${e.toString()}');
    }
  }

  // ── Change password sheet ──────────────────────────────────────────────────

  void _showChangePassword() {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1B2160),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
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
                  _pwField(
                    ctrl: newCtrl,
                    label: 'New Password',
                    obscure: obscureNew,
                    onToggle: () =>
                        setSheet(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 12),
                  _pwField(
                    ctrl: confirmCtrl,
                    label: 'Confirm New Password',
                    obscure: obscureConfirm,
                    onToggle: () =>
                        setSheet(() => obscureConfirm = !obscureConfirm),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final pw = newCtrl.text.trim();
                              final cf = confirmCtrl.text.trim();
                              if (pw.isEmpty || cf.isEmpty) {
                                _snack('Please fill all fields.');
                                return;
                              }
                              if (pw != cf) {
                                _snack('Passwords do not match.');
                                return;
                              }
                              if (pw.length < 6) {
                                _snack(
                                    'Password must be at least 6 characters.');
                                return;
                              }
                              setSheet(() => saving = true);
                              try {
                                await Supabase.instance.client.auth
                                    .updateUser(
                                  UserAttributes(password: pw),
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  _snack('Password updated!', success: true);
                                }
                              } catch (e) {
                                setSheet(() => saving = false);
                                _snack('Error: ${e.toString()}');
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
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Update Password',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
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

  // ── Password field helper ─────────────────────────────────────────────────

  Widget _pwField({
    required TextEditingController ctrl,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white38),
          onPressed: onToggle,
        ),
      ),
    );
  }

  // ── Avatar initials ───────────────────────────────────────────────────────

  String get _initials {
    final name = _displayName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1C2363),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2363),
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C3BFF)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                // ── Avatar ──────────────────────────────────────────────────
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5C3BFF), Color(0xFF00E5A0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                              color: Colors.white24, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Email label under avatar ────────────────────────────────
                Center(
                  child: Text(
                    _email ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Edit Display Name ───────────────────────────────────────
                _sectionLabel('PERSONAL INFO'),
                const SizedBox(height: 10),
                _card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Display Name',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameCtrl,
                                style:
                                    const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Enter your name',
                                  hintStyle: const TextStyle(
                                      color: Colors.white30),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.07),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed:
                                    _savingName ? null : _saveName,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF5C3BFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18),
                                ),
                                child: _savingName
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Text('Save',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Email (read-only)
                        const Text('Email',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _email ?? '—',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Subscription ─────────────────────────────────────────────
                _sectionLabel('SUBSCRIPTION'),
                const SizedBox(height: 10),
                _card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.workspace_premium_rounded,
                            color: Color(0xFFFFB800)),
                        title: Text(l.settingsCurrentPlan,
                            style:
                                const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          (_planName == null || _planName == 'Free Plan')
                              ? l.drawerFreePlan
                              : _planName!,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                      ),
                      const Divider(
                          color: Colors.white10, height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB800)),
                        title: Text(l.settingsManageSub,
                            style:
                                const TextStyle(color: Colors.white)),
                        subtitle: Text(l.settingsManageSubSub,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                        trailing: const Icon(Icons.chevron_right,
                            color: Colors.white38),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SubscribeScreen()),
                          );
                          if (mounted) _loadAccountInfo();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Security ─────────────────────────────────────────────────
                _sectionLabel('SECURITY'),
                const SizedBox(height: 10),
                _card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFF5C3BFF)),
                    title: Text(l.settingsChangePassword,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(l.settingsChangePasswordSub,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                    trailing: const Icon(Icons.chevron_right,
                        color: Colors.white38),
                    onTap: _showChangePassword,
                  ),
                ),
              ],
            ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: child,
      );
}
