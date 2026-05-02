import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:SecTunnel/core/logging/logger.dart';
import 'package:SecTunnel/services/proxy/mobile_proxy_service.dart';
import 'package:SecTunnel/models/rotation_log.dart';
import 'package:SecTunnel/models/ip_info.dart';

// ─── State Machine ──────────────────────────────────────────────
enum RotationState {
  idle,
  connecting,
  rotating,
  validating,
  success,
  failed,
}

// ─── Quality Scoring ────────────────────────────────────────────
class _QualityScorer {
  static const _targetCountries = ['Indonesia', 'ID'];

  static int calculate(IpInfo info) {
    int score = 0;
    if (_targetCountries.contains(info.country)) score += 30;
    if (!info.isProxy) score += 20;
    if (info.isp != null && info.isp!.isNotEmpty) score += 20;
    if (info.latencyMs != null && info.latencyMs! < 100) score += 30;
    return score.clamp(0, 100);
  }
}

// ─── Orchestrator Service ───────────────────────────────────────
/// Business logic layer for IP rotation.
/// Owns all rotation state per profile. Notifies UI via ChangeNotifier.
///
/// Flow:  UI → ModemRotatorService → MobileProxyService → ApiClient
class ModemRotatorService extends ChangeNotifier {
  final MobileProxyService _proxyService;
  final AppLogger _log = AppLogger.instance;

  // ── Per-Profile State ──────────────────────────────────────
  final Map<String, RotationState> _states = {};
  final Map<String, String> _errors = {};
  final Map<String, String> _names = {};
  final Map<String, DateTime> _cooldownUntil = {};
  final Map<String, int> _consecutiveFailures = {};
  final Map<String, int> _healthScores = {};
  final Map<String, IpInfo> _lastIpInfos = {};

  // ── Rotation History ───────────────────────────────────────
  final List<RotationLog> _logs = [];
  List<RotationLog> get logs => List.unmodifiable(_logs);

  final Random _rnd = Random();
  Timer? _countdownTimer;

  static const Duration _validationDelay = Duration(seconds: 15);
  static const Duration _resetDelay = Duration(seconds: 3);

  ModemRotatorService([MobileProxyService? proxyService])
      : _proxyService = proxyService ?? MobileProxyService() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer _) {
    final now = DateTime.now();
    final hasActive = _cooldownUntil.values.any((d) => d.isAfter(now));
    if (hasActive) notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    super.dispose();
  }

  // ─── Public Getters ─────────────────────────────────────────

  bool get isRotating => _states.values.any(_isBusyState);

  String? get activeProfileId =>
      _states.entries
          .where((e) => _isBusyState(e.value))
          .map((e) => e.key)
          .firstOrNull ??
      _states.entries
          .where((e) => e.value != RotationState.idle)
          .map((e) => e.key)
          .firstOrNull;

  String? get activeProfileName {
    final id = activeProfileId;
    return id == null ? null : _names[id];
  }

  String? get errorMessage {
    final id = activeProfileId;
    return id == null ? null : _errors[id];
  }

  RotationState getState(String profileId) =>
      _states[profileId] ?? RotationState.idle;

  String? getError(String profileId) => _errors[profileId];

  int getHealthScore(String profileId) =>
      _healthScores[profileId] ?? 100;

  int getConsecutiveFailures(String profileId) =>
      _consecutiveFailures[profileId] ?? 0;

  IpInfo? getIpInfo(String profileId) => _lastIpInfos[profileId];

  int getRemainingCooldownSeconds(String profileId) {
    final until = _cooldownUntil[profileId];
    if (until == null) return 0;
    final diff = until.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  bool isCoolingDown(String profileId) =>
      getRemainingCooldownSeconds(profileId) > 0;

  /// Returns the last N logs for a specific profile.
  List<RotationLog> getProfileLogs(String profileId, [int limit = 5]) {
    return _logs
        .where((l) => l.profileId == profileId)
        .toList()
        .reversed
        .take(limit)
        .toList();
  }

  // ─── Main Rotation Flow ─────────────────────────────────────

  Future<void> rotateIp(String profileId, [String? profileName]) async {
    // Store name for overlay display
    if (profileName != null) _names[profileId] = profileName;

    // Guard: already busy
    if (_isBusyState(getState(profileId))) return;

    // Guard: cooling down
    if (isCoolingDown(profileId)) return;

    _setState(profileId, RotationState.connecting);

    IpInfo? oldInfo;
    IpInfo? newInfo;
    bool ipChanged = false;
    bool success = false;
    int qualityScore = 0;
    IpQuality quality = IpQuality.unknown;

    try {
      // Step 1: capture current IP
      oldInfo = await _proxyService.getIpInfo();
      _log.info(LogTag.rotate, 'Current IP: ${oldInfo.ip}', profileId: profileId);

      // Step 2: trigger rotation
      _setState(profileId, RotationState.rotating);
      await _proxyService.rotateIp();

      // Step 3: wait for modem to apply new IP
      _setState(profileId, RotationState.validating);
      await Future.delayed(_validationDelay);

      // Step 4: verify new IP
      newInfo = await _proxyService.getIpInfo();

      // Step 5: compare
      if (oldInfo.ip == newInfo.ip) {
        throw const RotationException(
          RotationErrorType.ipNotChanged,
          'IP did not change after rotation',
        );
      }

      // Step 6: score quality
      ipChanged = true;
      success = true;
      qualityScore = _QualityScorer.calculate(newInfo);
      quality = IpQuality.fromScore(qualityScore);
      _lastIpInfos[profileId] = newInfo;

      _setState(profileId, RotationState.success);
      _log.info(LogTag.rotate, 'IP → ${newInfo.ip}', profileId: profileId);
      _log.info(LogTag.validation, 'COUNTRY: ${newInfo.country ?? "Unknown"} | ISP: ${newInfo.isp ?? "Unknown"}', profileId: profileId);
      _log.info(LogTag.validation, 'QUALITY: ${quality.label} ($qualityScore)', profileId: profileId);

    } on RotationException catch (e) {
      _log.error(LogTag.rotate, e.displayMessage, profileId: profileId, state: 'failed');
      _setState(profileId, RotationState.failed, error: e.displayMessage);
    } catch (e) {
      _log.error(LogTag.rotate, 'Unexpected: $e', profileId: profileId, state: 'failed');
      _setState(profileId, RotationState.failed, error: 'Rotation failed');
    } finally {
      // Health + cooldown update
      final cooldown = _updateHealthAndCooldown(profileId, success);

      // Record log
      _logs.add(RotationLog(
        profileId: profileId,
        timestamp: DateTime.now(),
        oldIp: oldInfo?.ip,
        newIp: newInfo?.ip,
        ipInfo: newInfo,
        qualityScore: qualityScore,
        quality: quality,
        ipChanged: ipChanged,
        isSuccess: success,
        error: success ? null : getError(profileId),
        cooldownApplied: cooldown,
        healthScoreAfter: getHealthScore(profileId),
      ));

      // Auto-reset to idle after brief display
      _scheduleReset(profileId);
    }
  }

  // ─── Internal Helpers ───────────────────────────────────────

  static bool _isBusyState(RotationState s) =>
      s == RotationState.connecting ||
      s == RotationState.rotating ||
      s == RotationState.validating;

  void _setState(String profileId, RotationState state, {String? error}) {
    _states[profileId] = state;
    if (error != null) {
      _errors[profileId] = error;
    } else if (state == RotationState.idle || state == RotationState.connecting) {
      _errors.remove(profileId);
    }
    _log.info(LogTag.rotate, '${state.name.toUpperCase()}${error != null ? " → $error" : ""}', profileId: profileId);
    notifyListeners();
  }

  Duration _updateHealthAndCooldown(String profileId, bool success) {
    int health = getHealthScore(profileId);
    int fails = getConsecutiveFailures(profileId);

    Duration cooldown;
    if (success) {
      health = (health + 20).clamp(0, 100);
      fails = 0;
      cooldown = Duration(seconds: 15 + _rnd.nextInt(16)); // 15–30s
    } else {
      health = (health - 30).clamp(0, 100);
      fails += 1;
      cooldown = fails >= 3
          ? Duration(seconds: 60 + _rnd.nextInt(61))  // 60–120s
          : Duration(seconds: 30 + _rnd.nextInt(31));  // 30–60s
    }

    _healthScores[profileId] = health;
    _consecutiveFailures[profileId] = fails;
    _cooldownUntil[profileId] = DateTime.now().add(cooldown);

    _log.info(LogTag.cooldown, 'health=$health fails=$fails cooldown=${cooldown.inSeconds}s', profileId: profileId);

    return cooldown;
  }

  void _scheduleReset(String profileId) {
    Timer(_resetDelay, () {
      final current = getState(profileId);
      if (current == RotationState.success || current == RotationState.failed) {
        _setState(profileId, RotationState.idle);
        // Clean name ref when no profiles are active
        if (!isRotating) _names.remove(profileId);
      }
    });
  }
}
