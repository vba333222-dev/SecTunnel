import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sec_tunnel/core/logging/logger.dart';
import 'package:sec_tunnel/services/proxy/mobile_proxy_service.dart';
import 'package:sec_tunnel/models/rotation_log.dart';
import 'package:sec_tunnel/models/ip_info.dart';
import 'package:sec_tunnel/services/operation/profile_health_service.dart';
import 'package:sec_tunnel/models/operation/profile_health.dart';

// ─── State Machine ──────────────────────────────────────────────
enum RotationState {
  idle,
  rotating,
  waitingModem,
  stabilizing,
  fetchingIp,
  verifying,
  success,
  failed,
}

// ─── Orchestrator Service ───────────────────────────────────────
class ModemRotatorService extends ChangeNotifier {
  final MobileProxyService _proxyService;
  final ProfileHealthService _healthService = ProfileHealthService();
  static const _platform = MethodChannel('com.example.pbrowser/proxy');

  // ── Per-Profile State ──────────────────────────────────────
  final Map<String, RotationState> _states = {};
  final Map<String, String> _errors = {};
  final Map<String, DateTime> _lastRotated = {};
  final Map<String, int> _healthScores = {};
  final Map<String, IpInfo> _lastIpInfos = {};
  final Map<String, int> _consecutiveFailures = {};

  // Global tracking for overlay
  String? _activeProfileId;
  String? _activeProfileName;

  bool _isBusy = false;
  bool get isBusyGlobal => _isBusy;

  final List<RotationLog> _logs = [];
  List<RotationLog> get logs => List.unmodifiable(_logs);

  Timer? _countdownTimer;

  ModemRotatorService({MobileProxyService? proxyService})
      : _proxyService = proxyService ?? MobileProxyService() {
    _startCooldownTimer();
  }

  // ─── Public API (State Getters) ──────────────────────────────

  RotationState getStatus(String profileId) => _states[profileId] ?? RotationState.idle;
  RotationState getState(String profileId) => getStatus(profileId); // Alias
  
  String? getError(String profileId) => _errors[profileId];
  IpInfo? getLastIp(String profileId) => _lastIpInfos[profileId];
  IpInfo? getIpInfo(String profileId) => getLastIp(profileId); // Alias

  int getHealthScore(String profileId) => _healthScores[profileId] ?? 100;
  int getConsecutiveFailures(String profileId) => _consecutiveFailures[profileId] ?? 0;

  int getRemainingCooldownSeconds(String profileId) {
    final last = _lastRotated[profileId];
    if (last == null) return 0;
    
    final health = _healthService.getHealth(profileId, getProfileLogs(profileId, 50));
    
    // Healthy Mobile Cooldown: 
    // Low Risk: 5 mins (300s)
    // Medium Risk: 10 mins (600s)
    // High/Critical: 30 mins (1800s)
    int cooldown;
    switch (health.risk) {
      case RiskLevel.low:
        cooldown = 300;
        break;
      case RiskLevel.medium:
        cooldown = 600;
        break;
      default:
        cooldown = 1800;
    }

    final diff = DateTime.now().difference(last).inSeconds;
    return (cooldown - diff).clamp(0, cooldown);
  }

  bool isCoolingDown(String profileId) => getRemainingCooldownSeconds(profileId) > 0;

  bool isBusy(String profileId) => _isBusyState(getStatus(profileId));

  // Overlay support
  String? get activeProfileName => _activeProfileName;
  bool get isRotating => _activeProfileId != null && isBusy(_activeProfileId!);
  String? get errorMessage => _activeProfileId != null ? getError(_activeProfileId!) : null;

  /// Returns the last N logs for a specific profile.
  List<RotationLog> getProfileLogs(String profileId, [int limit = 5]) {
    return _logs
        .where((l) => l.profileId == profileId)
        .toList()
        .reversed
        .take(limit)
        .toList();
  }

 /// The main IP rotation lifecycle.
  Future<bool> rotateIp(String profileId, String profileName) async {
    if (isBusy(profileId)) return false;
    if (isCoolingDown(profileId)) return false;

    // [STRICT LOCK] Set state immediately to prevent race conditions from spam clicks
    _setState(profileId, RotationState.rotating);
    
    _activeProfileId = profileId;
    _activeProfileName = profileName;
    _isBusy = true;
    notifyListeners();

    // Task 5: Natural Operational Cadence (Randomized Human Pause)
    final naturalPause = 5 + (Random().nextInt(10)); 
    AppLogger.instance.info(LogTag.rotate, 'Observing natural pause ($naturalPause s) before initiation...', profileId: profileId);
    await Future.delayed(Duration(seconds: naturalPause));

    final stopwatch = Stopwatch()..start();
    const stabilizationSeconds = 5;

    IpInfo? oldInfo;
    IpInfo? newInfo;
    bool success = false;

    try {
      // Step 0: Get initial IP for comparison
      AppLogger.instance.info(LogTag.rotate, 'Fetching baseline IP...', profileId: profileId);
      
      // [PERBAIKAN KUNCI] Tangkap error di sini agar rotasi tetap berjalan meski proxy saat ini sedang mati/500
      try {
        oldInfo = await _proxyService.getIpInfo();
        AppLogger.instance.info(LogTag.rotate, 'Baseline IP: ${oldInfo.ip}', profileId: profileId);
      } catch (e) {
        AppLogger.instance.warn(LogTag.rotate, 'Proxy is currently offline ($e). Forcing rotation...', profileId: profileId);
      }

      // Step 1: Call /rotate (Strict Fire-and-Forget)
      try {
        AppLogger.instance.info(LogTag.rotate, 'Sending rotate command...', profileId: profileId);
        await _proxyService.rotateIp();
        AppLogger.instance.info(LogTag.rotate, 'Rotate command accepted by server.', profileId: profileId);
      } catch (e) {
        // [RESILIENCE] If /rotate fails (e.g. timeout during modem cut-off), we MUST proceed to polling.
        // We do NOT retry /rotate to avoid stressing the hardware.
        AppLogger.instance.warn(
          LogTag.rotate, 
          'Rotate trigger exception ($e). Proceeding directly to polling...', 
          profileId: profileId
        );
      }

      // Step 2: Poll /status until 901 (Disconnected-Aware Polling)
      _setState(profileId, RotationState.waitingModem);
      const pollTimeout = 45; // Ditingkatkan ke 45 detik sesuai permintaan
      const pollDelay = Duration(seconds: 3); // 3 detik delay polling

      while (stopwatch.elapsed.inSeconds < pollTimeout) {
        try {
          final status = await _proxyService.getRotationStatus();
          final stateCode = status['state']; 
          
          if (stateCode == 901 || 
              stateCode == '901' || 
              stateCode.toString().toUpperCase() == 'DONE') {
            AppLogger.instance.info(LogTag.rotate, 'Modem ready ($stateCode).', profileId: profileId);
            break;
          } else {
             AppLogger.instance.info(LogTag.rotate, 'Modem state: $stateCode. Still waiting...', profileId: profileId);
          }
        } catch (e) {
          // Hiraukan error jaringan karena terowongan mungkin belum pulih
          AppLogger.instance.warn(
            LogTag.rotate, 
            'Waiting for Tunnel recovery... (${stopwatch.elapsed.inSeconds}s)', 
            profileId: profileId
          );
        }
        
        await Future.delayed(pollDelay);
        
        if (stopwatch.elapsed.inSeconds >= pollTimeout) {
          throw const RotationException(
            RotationErrorType.serverTimeout, 
            'Modem rotation timed out. Connection failed to recover after 45s.'
          );
        }
      }

      // Step 3: Stabilization Delay
      _setState(profileId, RotationState.stabilizing);
      await Future.delayed(const Duration(seconds: stabilizationSeconds));

      // Step 3.5: Apply Native Proxy
      final host = dotenv.env['PROXY_HOST'] ?? '35.198.231.6';
      final port = int.tryParse(dotenv.env['PROXY_PORT'] ?? '8080') ?? 8080;
      await _platform.invokeMethod('flushCookies');
      await _platform.invokeMethod('setProxy', {'host': host, 'port': port, 'scheme': 'http'});

      // Step 4: Fetch REAL IP (proxy-aware) with retry logic
      _setState(profileId, RotationState.fetchingIp);
      newInfo = await _fetchIpWithRetry(profileId);
      AppLogger.instance.info(LogTag.rotate, 'New IP detected: ${newInfo.ip}', profileId: profileId);

      // Step 5: Verify IP Change
      _setState(profileId, RotationState.verifying);
      if (oldInfo != null && oldInfo.ip == newInfo.ip) {
        throw const RotationException(RotationErrorType.ipNotChanged, 'IP did not change');
      }

      // Task 1 & 3: ASN Coherence Check
      if (oldInfo != null && oldInfo.isp != newInfo.isp) {
         AppLogger.instance.warn(
           LogTag.rotate, 
           'Network Continuity Event: ASN Shift detected (${oldInfo.isp} -> ${newInfo.isp})', 
           profileId: profileId
         );
      }

      success = true;
      _lastIpInfos[profileId] = newInfo;
      _consecutiveFailures[profileId] = 0;
      _setState(profileId, RotationState.success);
      AppLogger.instance.info(LogTag.rotate, 'Rotation successful: ${newInfo.ip}', profileId: profileId);

      return true;

    } catch (e) {
      final errorMsg = e is RotationException ? e.displayMessage : e.toString();
      AppLogger.instance.error(LogTag.rotate, 'Rotation failed: $errorMsg', profileId: profileId);

      _consecutiveFailures[profileId] = (_consecutiveFailures[profileId] ?? 0) + 1;
      _setState(profileId, RotationState.failed, error: errorMsg);
      
      _isBusy = false;
      notifyListeners();
      return false;
      
    } finally {
      _isBusy = false;
      stopwatch.stop();
      _updateHealthAndCooldown(profileId, success, oldInfo?.ip, newInfo?.ip);
      _scheduleReset(profileId);
      notifyListeners();
    }
  }

  // ─── Internal Helpers ───────────────────────────────────────

  static bool _isBusyState(RotationState s) =>
      s != RotationState.idle && s != RotationState.success && s != RotationState.failed;

  void _setState(String profileId, RotationState state, {String? error}) {
    _states[profileId] = state;
    if (error != null) {
      _errors[profileId] = error;
    } else if (state == RotationState.idle || state == RotationState.rotating) {
      _errors.remove(profileId);
    }
    AppLogger.instance.info(LogTag.rotate, 'STATE: ${state.name.toUpperCase()}', profileId: profileId);
    notifyListeners();
  }

  void _updateHealthAndCooldown(String profileId, bool success, String? oldIp, String? newIp) {
    _lastRotated[profileId] = DateTime.now();
    final currentHealth = _healthScores[profileId] ?? 100;
    _healthScores[profileId] = success ? (currentHealth + 5).clamp(0, 100) : (currentHealth - 20).clamp(0, 100);
    
    // Log to persistent list
    _logs.add(RotationLog(
      profileId: profileId,
      timestamp: DateTime.now(),
      isSuccess: success,
      oldIp: oldIp,
      newIp: newIp,
      error: _errors[profileId],
      cooldownApplied: const Duration(seconds: 15),
      healthScoreAfter: _healthScores[profileId]!,
      ipChanged: oldIp != newIp && success,
    ));
    
    if (_logs.length > 100) _logs.removeAt(0);
  }

  void _startCooldownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) => notifyListeners());
  }

  void _scheduleReset(String profileId) {
    Future.delayed(const Duration(seconds: 5), () {
      // Clear global tracking so the overlay/progress bar disappears
      if (_activeProfileId == profileId) {
        _activeProfileId = null;
        _activeProfileName = null;
      }
      
      // If it failed, reset to idle so user can retry clearly.
      // If it succeeded, STAY at success so the Launch button remains active.
      if (_states[profileId] == RotationState.failed) {
        _states[profileId] = RotationState.idle;
      }
      
      notifyListeners();
    });
  }

  /// Internal helper to fetch IP with retries during stabilization phase.
  Future<IpInfo> _fetchIpWithRetry(String profileId) async {
    int attempts = 0;
    const maxAttempts = 3;
    const retryDelay = Duration(seconds: 3);

    while (attempts < maxAttempts) {
      try {
        return await _proxyService.getIpInfo();
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) rethrow;
        AppLogger.instance.warn(
          LogTag.rotate, 
          'IP fetch failed (attempt $attempts/$maxAttempts). Waiting for connection stability...', 
          profileId: profileId
        );
        await Future.delayed(retryDelay);
      }
    }
    throw const RotationException(RotationErrorType.validationFailed, 'Failed to verify IP after retries');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
