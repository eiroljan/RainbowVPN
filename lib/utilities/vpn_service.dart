import 'dart:async';
import 'package:flutter/services.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:vpn_app/models/vpn_server_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL TEST MODE FLAG
//
// Set `kLocalTestMode = true`  → uses the built-in mock that simulates the
//   full connection lifecycle without any server or network.  Works on every
//   emulator / physical device immediately.
//
// Set `kLocalTestMode = false` → uses the real OpenVPN engine.  Point your
//   .ovpn files at a real server (local Docker server or production).
// ─────────────────────────────────────────────────────────────────────────────
const bool kLocalTestMode = false;

/// A thin wrapper around [OpenVPN] that manages initialization, connection,
/// and disconnection in one place. Use [VpnService.instance] everywhere.
///
/// When [kLocalTestMode] is `true` all OpenVPN calls are replaced by a
/// timer-driven state machine so UI flows can be tested without any server.
class VpnService {
  VpnService._();
  static final VpnService instance = VpnService._();

  // ── Real OpenVPN engine (used when kLocalTestMode == false) ───────────────
  late OpenVPN _openVPN;
  bool _initialized = false;

  // ── Mock state (used when kLocalTestMode == true) ─────────────────────────
  Timer? _mockSequenceTimer;
  Timer? _statsTimer;
  double _mockRxBytes = 0;
  double _mockTxBytes = 0;

  /// The most recent VPN connection status (bytes, duration, etc.).
  VpnStatus? status;

  /// The most recent VPN stage (connecting, connected, disconnected, etc.).
  VPNStage? stage;

  // Callbacks — set these from the widget that owns the UI.
  void Function(VpnStatus?)? onStatusChanged;
  void Function(VPNStage?)? onStageChanged;

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Must be called once before any connect/disconnect call.
  ///
  /// [groupIdentifier] and [providerBundleIdentifier] are iOS-only. You can
  /// leave them as the defaults shown here for Android-only builds.
  void initialize({
    String groupIdentifier = 'group.com.example.vpn_app',
    String providerBundleIdentifier = 'com.example.vpn_app.VPNExtension',
    String localizedDescription = 'VPN App',
  }) {
    if (_initialized) return;

    if (!kLocalTestMode) {
      _openVPN = OpenVPN(
        onVpnStatusChanged: _handleStatus,
        onVpnStageChanged: _handleStage,
      );

      _openVPN.initialize(
        groupIdentifier: groupIdentifier,
        providerBundleIdentifier: providerBundleIdentifier,
        localizedDescription: localizedDescription,
      );
    }

    _initialized = true;
  }

  // ── Real OpenVPN callbacks ─────────────────────────────────────────────────

  void _handleStatus(VpnStatus? s) {
    status = s;
    onStatusChanged?.call(s);
  }

  void _handleStage(VPNStage vpnStage, String message) {
    stage = vpnStage;
    onStageChanged?.call(vpnStage);
  }

  // ── Connect ────────────────────────────────────────────────────────────────

  /// Connects to [server] by loading its bundled `.ovpn` asset, then calling
  /// [OpenVPN.connect].
  ///
  /// In [kLocalTestMode] this runs a timer-based state machine instead.
  Future<void> connect(VpnServerModel server) async {
    assert(_initialized, 'Call initialize() first');

    if (kLocalTestMode) {
      await _mockConnect();
      return;
    }

    // Load the .ovpn config from the assets bundle
    final config = await rootBundle.loadString(server.configAssetPath);

    _openVPN.connect(
      config,
      server.country,
      username: server.username.isNotEmpty ? server.username : null,
      password: server.password.isNotEmpty ? server.password : null,
      certIsRequired: false, // set true if your server requires a client cert
    );
  }

  // ── Disconnect ─────────────────────────────────────────────────────────────

  /// Disconnects the active VPN tunnel.
  void disconnect() {
    assert(_initialized, 'Call initialize() first');

    if (kLocalTestMode) {
      _mockDisconnect();
      return;
    }

    _openVPN.disconnect();
  }

  // ── Mock implementation ────────────────────────────────────────────────────

  /// Simulates the full OpenVPN connection lifecycle:
  ///   prepare (0 s) → authenticating (+1.2 s) → connected (+1.6 s)
  ///
  /// After connecting a stats ticker fires every second with increasing
  /// byte counters to simulate realistic download / upload traffic.
  Future<void> _mockConnect() async {
    _cancelMockTimers();
    _mockRxBytes = 0;
    _mockTxBytes = 0;

    _emitStage(VPNStage.prepare);

    // Authenticating after 1.2 s
    _mockSequenceTimer = Timer(const Duration(milliseconds: 1200), () {
      _emitStage(VPNStage.authenticating);

      // Connected after another 1.6 s
      _mockSequenceTimer = Timer(const Duration(milliseconds: 1600), () {
        _emitStage(VPNStage.connected);
        _startMockStats();
      });
    });
  }

  /// Simulates a clean disconnection:
  ///   disconnecting (0 s) → disconnected (+0.9 s)
  void _mockDisconnect() {
    _cancelMockTimers();
    _emitStage(VPNStage.disconnecting);

    _mockSequenceTimer = Timer(const Duration(milliseconds: 900), () {
      _emitStage(VPNStage.disconnected);
    });
  }

  /// Fires a [VpnStatus] update every second with gradually increasing
  /// byte counters to simulate real traffic.
  void _startMockStats() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Simulate 2–8 MB/s download, 0.5–2 MB/s upload (cumulative bytes)
      final now = DateTime.now().millisecond;
      _mockRxBytes += (2 + (now % 6)) * 1024 * 1024;
      _mockTxBytes += (0.5 + (now % 2)) * 1024 * 1024;

      final mockStatus = VpnStatus(
        byteIn: _mockRxBytes.toStringAsFixed(0),
        byteOut: _mockTxBytes.toStringAsFixed(0),
        connectedOn: DateTime.now(),
      );
      status = mockStatus;
      onStatusChanged?.call(mockStatus);
    });
  }

  void _cancelMockTimers() {
    _mockSequenceTimer?.cancel();
    _statsTimer?.cancel();
    _mockSequenceTimer = null;
    _statsTimer = null;
  }

  void _emitStage(VPNStage s) {
    stage = s;
    onStageChanged?.call(s);
  }

  // ── Convenience getters ────────────────────────────────────────────────────

  /// Convenience getter — true when fully connected.
  bool get isConnected => stage == VPNStage.connected;

  /// Convenience getter — true while in a transitional state.
  bool get isConnecting {
    if (stage == null) return false;
    return stage != VPNStage.connected &&
        stage != VPNStage.disconnected &&
        stage != VPNStage.denied &&
        stage != VPNStage.error &&
        stage != VPNStage.unknown;
  }

  /// Friendly one-line status label for the UI.
  String get stageLabel {
    switch (stage) {
      case VPNStage.connected:
        return 'Connected';
      case VPNStage.connecting:
      case VPNStage.prepare:
        return 'Connecting...';
      case VPNStage.authenticating:
      case VPNStage.authentication:
        return 'Authenticating...';
      case VPNStage.disconnecting:
        return 'Disconnecting...';
      case VPNStage.denied:
        return 'Permission Denied';
      case VPNStage.error:
        return 'Error';
      default:
        return 'Not Connected';
    }
  }
}
