import 'package:flutter/material.dart';

/// Hand-rolled localizations supporting English (en) and Simplified Chinese (zh).
///
/// Add this delegate to MaterialApp.localizationsDelegates and list the
/// supported locales in MaterialApp.supportedLocales.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ── String tables ──────────────────────────────────────────────────────────

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'appTitle': 'VPN',
      'getStarted': 'Get Started',
      'alreadyHaveAccount': 'Already have an account? ',
      'signIn': 'Sign in',
      'welcomeTagline':
          'Login now to access faster internet in\nmore than 120+ location',

      'loginTitle': 'Sign In',
      'loginSubtitle':
          'Welcome back! Login to continue\nyour secure VPN experience.',
      'emailHint': 'Email address',
      'passwordHint': 'Password',
      'forgotPassword': 'Forgot password?',
      'login': 'Login',
      'noAccount': "Don't have an account? ",
      'signUp': 'Sign up',

      'signUpTitle': 'Create Account',
      'signUpSubtitle': 'Sign up to get started with\nyour secure VPN experience.',
      'nameHint': 'Full name',

      'serverLocation': 'Server Location',
      'selectServer': 'Select Server',
      'download': 'Download',
      'upload': 'Upload',
      'duration': 'Duration',
      'noLogPolicy': 'No-Log Policy',
      'ultraFast': 'Ultra Fast',
      'aes256': 'AES-256',

      'statusConnected': 'Connected',
      'statusConnecting': 'Connecting...',
      'statusAuthenticating': 'Authenticating...',
      'statusDisconnecting': 'Disconnecting...',
      'statusPermissionDenied': 'Permission Denied',
      'statusError': 'Error',
      'statusNotConnected': 'Not Connected',

      'navHome': 'Home',
      'navServers': 'Servers',
      'navStats': 'Stats',
      'navSettings': 'Settings',

      'errorVpnPermissionDenied':
          'VPN permission denied. Please grant the VPN permission.',
      'errorVpnConnection':
          'VPN connection error. Check your .ovpn config.',
      'errorLoadConfig': 'Failed to load VPN config: ',

      'countryUnitedStates': 'United States',
      'countryUnitedKingdom': 'United Kingdom',
      'countryGermany': 'Germany',
      'countryJapan': 'Japan',
      'countrySingapore': 'Singapore',
      'countryAustralia': 'Australia',
      'countryCanada': 'Canada',
      'countryNetherlands': 'Netherlands',
    },
    'zh': {
      'appTitle': 'VPN',
      'getStarted': '立即开始',
      'alreadyHaveAccount': '已有账户？',
      'signIn': '登录',
      'welcomeTagline': '立即登录，畅享120+地区\n更快速的网络体验',

      'loginTitle': '登录',
      'loginSubtitle': '欢迎回来！登录后继续\n您的安全VPN体验。',
      'emailHint': '邮箱地址',
      'passwordHint': '密码',
      'forgotPassword': '忘记密码？',
      'login': '登录',
      'noAccount': '还没有账户？',
      'signUp': '注册',

      'signUpTitle': '创建账户',
      'signUpSubtitle': '注册以开始您的\n安全VPN体验。',
      'nameHint': '全名',

      'serverLocation': '服务器位置',
      'selectServer': '选择服务器',
      'download': '下载',
      'upload': '上传',
      'duration': '时长',
      'noLogPolicy': '无日志政策',
      'ultraFast': '超高速',
      'aes256': 'AES-256加密',

      'statusConnected': '已连接',
      'statusConnecting': '连接中...',
      'statusAuthenticating': '认证中...',
      'statusDisconnecting': '断开中...',
      'statusPermissionDenied': '权限被拒绝',
      'statusError': '错误',
      'statusNotConnected': '未连接',

      'navHome': '主页',
      'navServers': '服务器',
      'navStats': '统计',
      'navSettings': '设置',

      'errorVpnPermissionDenied': 'VPN权限被拒绝，请授予VPN权限。',
      'errorVpnConnection': 'VPN连接错误，请检查您的.ovpn配置。',
      'errorLoadConfig': '加载VPN配置失败：',

      'countryUnitedStates': '美国',
      'countryUnitedKingdom': '英国',
      'countryGermany': '德国',
      'countryJapan': '日本',
      'countrySingapore': '新加坡',
      'countryAustralia': '澳大利亚',
      'countryCanada': '加拿大',
      'countryNetherlands': '荷兰',
    },
  };

  // ── Accessor ───────────────────────────────────────────────────────────────

  String _t(String key) {
    final langCode = locale.languageCode;
    return _strings[langCode]?[key] ?? _strings['en']![key] ?? key;
  }

  // ── Getters (one per string key) ───────────────────────────────────────────

  String get appTitle => _t('appTitle');
  String get getStarted => _t('getStarted');
  String get alreadyHaveAccount => _t('alreadyHaveAccount');
  String get signIn => _t('signIn');
  String get welcomeTagline => _t('welcomeTagline');

  String get loginTitle => _t('loginTitle');
  String get loginSubtitle => _t('loginSubtitle');
  String get emailHint => _t('emailHint');
  String get passwordHint => _t('passwordHint');
  String get forgotPassword => _t('forgotPassword');
  String get login => _t('login');
  String get noAccount => _t('noAccount');
  String get signUp => _t('signUp');
    String get signUpTitle => _t('signUpTitle');
    String get signUpSubtitle => _t('signUpSubtitle');
    String get nameHint => _t('nameHint');

  String get serverLocation => _t('serverLocation');
  String get selectServer => _t('selectServer');
  String get download => _t('download');
  String get upload => _t('upload');
  String get duration => _t('duration');
  String get noLogPolicy => _t('noLogPolicy');
  String get ultraFast => _t('ultraFast');
  String get aes256 => _t('aes256');

  String get statusConnected => _t('statusConnected');
  String get statusConnecting => _t('statusConnecting');
  String get statusAuthenticating => _t('statusAuthenticating');
  String get statusDisconnecting => _t('statusDisconnecting');
  String get statusPermissionDenied => _t('statusPermissionDenied');
  String get statusError => _t('statusError');
  String get statusNotConnected => _t('statusNotConnected');

  String get navHome => _t('navHome');
  String get navServers => _t('navServers');
  String get navStats => _t('navStats');
  String get navSettings => _t('navSettings');

  String get errorVpnPermissionDenied => _t('errorVpnPermissionDenied');
  String get errorVpnConnection => _t('errorVpnConnection');
  String get errorLoadConfig => _t('errorLoadConfig');

  String get countryUnitedStates => _t('countryUnitedStates');
  String get countryUnitedKingdom => _t('countryUnitedKingdom');
  String get countryGermany => _t('countryGermany');
  String get countryJapan => _t('countryJapan');
  String get countrySingapore => _t('countrySingapore');
  String get countryAustralia => _t('countryAustralia');
  String get countryCanada => _t('countryCanada');
  String get countryNetherlands => _t('countryNetherlands');
}

// ── Delegate ───────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
