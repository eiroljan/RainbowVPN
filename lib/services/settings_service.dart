import 'package:shared_preferences/shared_preferences.dart';

/// Persists all user-configurable VPN settings using SharedPreferences.
///
/// Usage:
///   final s = await SettingsService.load();
///   s.autoConnect = true;
///   await s.save();
class SettingsService {
  SettingsService._({
    required this.autoConnect,
    required this.killSwitch,
    required this.protocol,
    required this.connNotifications,
    required this.dataAlerts,
    required this.language,
  });

  // ── Keys ────────────────────────────────────────────────────────────────────
  static const _kAutoConnect        = 'autoConnect';
  static const _kKillSwitch         = 'killSwitch';
  static const _kProtocol           = 'protocol';
  static const _kConnNotifications  = 'connNotifications';
  static const _kDataAlerts         = 'dataAlerts';
  static const _kLanguage           = 'language';

  // ── Fields ──────────────────────────────────────────────────────────────────
  bool   autoConnect;
  bool   killSwitch;
  String protocol;          // 'UDP' | 'TCP'
  bool   connNotifications;
  bool   dataAlerts;
  String language;          // 'en' | 'zh'

  // ── Factory: load from disk ─────────────────────────────────────────────────
  static Future<SettingsService> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService._(
      autoConnect:       prefs.getBool(_kAutoConnect)       ?? false,
      killSwitch:        prefs.getBool(_kKillSwitch)        ?? false,
      protocol:          prefs.getString(_kProtocol)        ?? 'UDP',
      connNotifications: prefs.getBool(_kConnNotifications) ?? true,
      dataAlerts:        prefs.getBool(_kDataAlerts)        ?? true,
      language:          prefs.getString(_kLanguage)        ?? 'en',
    );
  }

  // ── Persist to disk ─────────────────────────────────────────────────────────
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_kAutoConnect,       autoConnect),
      prefs.setBool(_kKillSwitch,        killSwitch),
      prefs.setString(_kProtocol,        protocol),
      prefs.setBool(_kConnNotifications, connNotifications),
      prefs.setBool(_kDataAlerts,        dataAlerts),
      prefs.setString(_kLanguage,        language),
    ]);
  }

  /// Convenience: save a single boolean key immediately.
  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Convenience: save a single string key immediately.
  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // Expose key constants publicly for individual saves
  static const autoConnectKey       = _kAutoConnect;
  static const killSwitchKey        = _kKillSwitch;
  static const protocolKey          = _kProtocol;
  static const connNotificationsKey = _kConnNotifications;
  static const dataAlertsKey        = _kDataAlerts;
  static const languageKey          = _kLanguage;
}
