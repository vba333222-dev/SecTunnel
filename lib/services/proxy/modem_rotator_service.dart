import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:SecTunnel/services/proxy/mobile_proxy_service.dart';
import 'package:SecTunnel/models/rotation_log.dart';
import 'package:SecTunnel/models/ip_info.dart';

enum RotationState {
  idle,
  connecting,
  rotating,
  validating,
  success,
  failed
}

class ModemRotatorService extends ChangeNotifier {
  final Map<String, RotationState> _states = {};
  final Map<String, String> _errors = {};
  final Map<String, String> _names = {};
  
  final Map<String, DateTime> _cooldownUntil = {};
  final Map<String, int> _consecutiveFailures = {};
  final Map<String, int> _healthScores = {};
  final Map<String, IpInfo> _ipInfos = {};

  final List<RotationLog> logs = [];
  final Random _rnd = Random();

  Timer? _countdownTimer;

  ModemRotatorService() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_cooldownUntil.values.any((d) => d.isAfter(DateTime.now()))) {
        notifyListeners(); 
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  static const Duration _resetDelay = Duration(seconds: 3);

  bool get isRotating => _states.values.any((s) => 
      s == RotationState.connecting || s == RotationState.rotating || s == RotationState.validating);
  
  String? get targetProfileId {
    final active = _states.entries.where((e) => 
        e.value == RotationState.connecting || e.value == RotationState.rotating || e.value == RotationState.validating).map((e) => e.key).firstOrNull;
    if (active != null) return active;
    return _states.entries.where((e) => e.value != RotationState.idle).map((e) => e.key).firstOrNull;
  }
  
  String? get targetProfileName {
    final id = targetProfileId;
    return id == null ? null : _names[id];
  }
  
  String? get errorMessage {
    final id = targetProfileId;
    return id == null ? null : _errors[id];
  }

  RotationState getState(String profileId) => _states[profileId] ?? RotationState.idle;
  String? getError(String profileId) => _errors[profileId];

  int getHealthScore(String profileId) => _healthScores[profileId] ?? 100;
  
  int getConsecutiveFailures(String profileId) => _consecutiveFailures[profileId] ?? 0;

  IpInfo? getIpInfo(String profileId) => _ipInfos[profileId];

  int getRemainingCooldownSeconds(String profileId) {
    final until = _cooldownUntil[profileId];
    if (until == null) return 0;
    final diff = until.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  bool isCoolingDown(String profileId) => getRemainingCooldownSeconds(profileId) > 0;

  int _calculateQualityScore(IpInfo info) {
    int score = 0;
    if (info.country == 'Indonesia' || info.country == 'ID') score += 30;
    if (!info.isProxy) score += 20;
    if (info.isp != null && info.isp!.isNotEmpty) score += 20;
    if (info.latencyMs != null && info.latencyMs! < 100) score += 30;
    return score.clamp(0, 100);
  }

  String _getQualityLabel(int score) {
    if (score >= 80) return 'GOOD';
    if (score >= 50) return 'OK';
    return 'BAD';
  }

  void _log(String profileId, RotationState state, String message) {
    debugPrint('[ROTATE][$profileId][${state.name.toUpperCase()}] $message');
  }

  void _setState(String profileId, RotationState state, {String? error}) {
    _states[profileId] = state;
    if (error != null) {
      _errors[profileId] = error;
    } else if (state == RotationState.idle || state == RotationState.connecting) {
      _errors.remove(profileId);
    }
    _log(profileId, state, error ?? 'State updated');
    notifyListeners();
  }

  Duration _updateHealthAndCooldown(String profileId, bool success) {
    int currentHealth = getHealthScore(profileId);
    int fails = getConsecutiveFailures(profileId);
    
    Duration cooldown;
    if (success) {
      currentHealth = (currentHealth + 20).clamp(0, 100);
      fails = 0;
      cooldown = Duration(seconds: 15 + _rnd.nextInt(16));
    } else {
      currentHealth = (currentHealth - 30).clamp(0, 100);
      fails += 1;
      if (fails >= 3) {
        cooldown = Duration(seconds: 60 + _rnd.nextInt(61));
      } else {
        cooldown = Duration(seconds: 30 + _rnd.nextInt(31));
      }
    }

    _healthScores[profileId] = currentHealth;
    _consecutiveFailures[profileId] = fails;
    _cooldownUntil[profileId] = DateTime.now().add(cooldown);
    
    return cooldown;
  }

  Future<void> rotateIp(String profileId, [String? profileName]) async {
    if (profileName != null) {
      _names[profileId] = profileName;
    }
    
    final currentState = getState(profileId);
    if (currentState == RotationState.connecting || currentState == RotationState.rotating || currentState == RotationState.validating) {
      return; 
    }

    if (isCoolingDown(profileId)) {
      return; 
    }

    _setState(profileId, RotationState.connecting);

    IpInfo? oldInfo;
    IpInfo? newInfo;
    bool isChanged = false;
    bool processSuccess = false;
    int qualityScore = 0;
    String qualityLabel = 'UNKNOWN';

    try {
      try {
        oldInfo = await MobileProxyService.getIpInfo();
      } catch (_) {
        throw ProxyRotationException('validation_failed');
      }

      _setState(profileId, RotationState.rotating);
      await MobileProxyService.rotateIp();

      _setState(profileId, RotationState.validating);
      await Future.delayed(const Duration(seconds: 15));

      try {
        newInfo = await MobileProxyService.getIpInfo();
      } catch (_) {
        throw ProxyRotationException('validation_failed');
      }

      if (oldInfo.ip == newInfo.ip) {
        throw ProxyRotationException('ip_not_changed');
      } else {
        isChanged = true;
        processSuccess = true;
        qualityScore = _calculateQualityScore(newInfo);
        qualityLabel = _getQualityLabel(qualityScore);
        _ipInfos[profileId] = newInfo;
        _setState(profileId, RotationState.success);

        debugPrint('[ROTATE][$profileId] IP -> ${newInfo.ip}');
        debugPrint('[ROTATE][$profileId] COUNTRY -> ${newInfo.country ?? "Unknown"}');
        debugPrint('[ROTATE][$profileId] QUALITY -> $qualityLabel ($qualityScore)');
      }

    } on ProxyRotationException catch (e) {
      _setState(profileId, RotationState.failed, error: e.message);
    } catch (e) {
      _setState(profileId, RotationState.failed, error: 'Rotation failed');
    } finally {
      final cooldownDuration = _updateHealthAndCooldown(profileId, processSuccess);
      final endState = getState(profileId);
      
      final logEntry = RotationLog(
        profileId: profileId,
        timestamp: DateTime.now(),
        oldIp: oldInfo?.ip,
        newIp: newInfo?.ip,
        ipInfo: newInfo,
        qualityScore: qualityScore,
        qualityLabel: qualityLabel,
        isChanged: isChanged,
        status: endState == RotationState.success ? 'SUCCESS' : 'FAILED',
        error: endState == RotationState.failed ? getError(profileId) : null,
        cooldownApplied: cooldownDuration,
        healthScoreAfter: getHealthScore(profileId),
      );
      logs.add(logEntry);

      Timer(_resetDelay, () {
        if (getState(profileId) == RotationState.success || getState(profileId) == RotationState.failed) {
          _setState(profileId, RotationState.idle);
          if (!isRotating) {
            _names.remove(profileId);
          }
        }
      });
    }
  }
}
