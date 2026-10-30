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
      'appTitle': 'RB VPN',
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
      'signUpSubtitle':
          'Sign up to get started with\nyour secure VPN experience.',
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

      'drawerUser': 'VPN User',
      'drawerFreePlan': 'Free Plan',
      'drawerProfile': 'Profile',
      'drawerSubscribe': 'Subscribe',
      'drawerUpgradePlan': 'Upgrade your plan',
      'drawerSettings': 'Settings',
      'drawerAbout': 'About',
      'drawerHelpSupport': 'Help & Support',
      'drawerShareApp': 'Share App',
      'drawerLogout': 'Logout',

      'settingsTitle': 'Settings',
      'settingsSubtitle': 'Customize your VPN experience',
      'settingsSectionConnection': 'Connection',
      'settingsAutoConnect': 'Auto-connect on Launch',
      'settingsAutoConnectSub': 'Automatically connect VPN when app opens',
      'settingsKillSwitch': 'Kill Switch',
      'settingsKillSwitchSub': 'Block internet if VPN connection drops',
      'settingsVpnProtocol': 'VPN Protocol',
      'settingsVpnProtocolSub':
          'UDP is faster. TCP is more reliable on restricted networks.',
      'settingsProtocolUdpSub': 'Faster speeds, lower latency',
      'settingsProtocolTcpSub': 'More reliable on firewalled networks',
      'settingsSectionAppearance': 'Appearance',
      'settingsLanguage': 'Language',
      'settingsSectionNotifications': 'Notifications',
      'settingsConnAlerts': 'Connection Alerts',
      'settingsConnAlertsSub': 'Notify when VPN connects or disconnects',
      'settingsDataAlerts': 'Data Usage Alerts',
      'settingsDataAlertsSub': 'Alert when session data exceeds 1 GB',
      'settingsSectionAccount': 'Account',
      'settingsEmail': 'Email',
      'settingsCurrentPlan': 'Current Plan',
      'settingsManageSub': 'Manage Subscription',
      'settingsManageSubSub': 'Upgrade or change your plan',
      'settingsChangePassword': 'Change Password',
      'settingsChangePasswordSub': 'Update your account password',
      'settingsNewPassword': 'New Password',
      'settingsConfirmNewPassword': 'Confirm New Password',
      'settingsUpdatePassword': 'Update Password',
      'settingsFillAllFields': 'Please fill all fields',
      'settingsPasswordsDoNotMatch': 'Passwords do not match',
      'settingsPasswordTooShort': 'Password must be at least 6 characters',
      'settingsPasswordUpdated': '✅ Password updated successfully',
      'settingsVersion': 'Version',

      'errorVpnPermissionDenied':
          'VPN permission denied. Please grant the VPN permission.',
      'errorVpnConnection': 'VPN connection error. Check your .ovpn config.',
      'errorLoadConfig': 'Failed to load VPN config: ',

      'countryUnitedStates': 'United States',
      'countryUnitedKingdom': 'United Kingdom',
      'countryGermany': 'Germany',
      'countryJapan': 'Japan',
      'countrySingapore': 'Singapore',
      'countryAustralia': 'Australia',
      'countryCanada': 'Canada',
      'countryNetherlands': 'Netherlands',
      'countryMalaysia': 'Malaysia',
    },
    'zh': {
      'appTitle': 'RB VPN',
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

      'drawerUser': 'VPN 用户',
      'drawerFreePlan': '免费计划',
      'drawerProfile': '个人资料',
      'drawerSubscribe': '订阅',
      'drawerUpgradePlan': '升级您的套餐',
      'drawerSettings': '设置',
      'drawerAbout': '关于',
      'drawerHelpSupport': '帮助与支持',
      'drawerShareApp': '分享应用',
      'drawerLogout': '退出登录',

      'settingsTitle': '设置',
      'settingsSubtitle': '自定义您的VPN体验',
      'settingsSectionConnection': '连接',
      'settingsAutoConnect': '启动时自动连接',
      'settingsAutoConnectSub': '打开应用时自动连接VPN',
      'settingsKillSwitch': 'Kill Switch (断网保护)',
      'settingsKillSwitchSub': 'VPN连接断开时切断网络以保护隐私',
      'settingsVpnProtocol': 'VPN 协议',
      'settingsVpnProtocolSub': 'UDP速度更快，TCP在受限网络中更稳定。',
      'settingsProtocolUdpSub': '速度更快，延迟更低',
      'settingsProtocolTcpSub': '在防火墙限制的网络中更稳定',
      'settingsSectionAppearance': '外观',
      'settingsLanguage': '语言',
      'settingsSectionNotifications': '通知',
      'settingsConnAlerts': '连接提醒',
      'settingsConnAlertsSub': 'VPN连接或断开时发送通知',
      'settingsDataAlerts': '流量使用提醒',
      'settingsDataAlertsSub': '单次连接流量超过 1 GB 时提醒',
      'settingsSectionAccount': '账户',
      'settingsEmail': '电子邮箱',
      'settingsCurrentPlan': '当前套餐',
      'settingsManageSub': '管理订阅',
      'settingsManageSubSub': '升级或更改您的套餐',
      'settingsChangePassword': '修改密码',
      'settingsChangePasswordSub': '更新您的账户密码',
      'settingsNewPassword': '新密码',
      'settingsConfirmNewPassword': '确认新密码',
      'settingsUpdatePassword': '更新密码',
      'settingsFillAllFields': '请填写所有字段',
      'settingsPasswordsDoNotMatch': '两次输入的密码不一致',
      'settingsPasswordTooShort': '密码长度必须至少为6个字符',
      'settingsPasswordUpdated': '✅ 密码更新成功',
      'settingsVersion': '版本',

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
      'countryMalaysia': '马来西亚',
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

  String get drawerUser => _t('drawerUser');
  String get drawerFreePlan => _t('drawerFreePlan');
  String get drawerProfile => _t('drawerProfile');
  String get drawerSubscribe => _t('drawerSubscribe');
  String get drawerUpgradePlan => _t('drawerUpgradePlan');
  String get drawerSettings => _t('drawerSettings');
  String get drawerAbout => _t('drawerAbout');
  String get drawerHelpSupport => _t('drawerHelpSupport');
  String get drawerShareApp => _t('drawerShareApp');
  String get drawerLogout => _t('drawerLogout');

  String get settingsTitle => _t('settingsTitle');
  String get settingsSubtitle => _t('settingsSubtitle');
  String get settingsSectionConnection => _t('settingsSectionConnection');
  String get settingsAutoConnect => _t('settingsAutoConnect');
  String get settingsAutoConnectSub => _t('settingsAutoConnectSub');
  String get settingsKillSwitch => _t('settingsKillSwitch');
  String get settingsKillSwitchSub => _t('settingsKillSwitchSub');
  String get settingsVpnProtocol => _t('settingsVpnProtocol');
  String get settingsVpnProtocolSub => _t('settingsVpnProtocolSub');
  String get settingsProtocolUdpSub => _t('settingsProtocolUdpSub');
  String get settingsProtocolTcpSub => _t('settingsProtocolTcpSub');
  String get settingsSectionAppearance => _t('settingsSectionAppearance');
  String get settingsLanguage => _t('settingsLanguage');
  String get settingsSectionNotifications => _t('settingsSectionNotifications');
  String get settingsConnAlerts => _t('settingsConnAlerts');
  String get settingsConnAlertsSub => _t('settingsConnAlertsSub');
  String get settingsDataAlerts => _t('settingsDataAlerts');
  String get settingsDataAlertsSub => _t('settingsDataAlertsSub');
  String get settingsSectionAccount => _t('settingsSectionAccount');
  String get settingsEmail => _t('settingsEmail');
  String get settingsCurrentPlan => _t('settingsCurrentPlan');
  String get settingsManageSub => _t('settingsManageSub');
  String get settingsManageSubSub => _t('settingsManageSubSub');
  String get settingsChangePassword => _t('settingsChangePassword');
  String get settingsChangePasswordSub => _t('settingsChangePasswordSub');
  String get settingsNewPassword => _t('settingsNewPassword');
  String get settingsConfirmNewPassword => _t('settingsConfirmNewPassword');
  String get settingsUpdatePassword => _t('settingsUpdatePassword');
  String get settingsFillAllFields => _t('settingsFillAllFields');
  String get settingsPasswordsDoNotMatch => _t('settingsPasswordsDoNotMatch');
  String get settingsPasswordTooShort => _t('settingsPasswordTooShort');
  String get settingsPasswordUpdated => _t('settingsPasswordUpdated');
  String get settingsVersion => _t('settingsVersion');

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
  String get countryMalaysia => _t('countryMalaysia');
}

// ── Delegate ───────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
