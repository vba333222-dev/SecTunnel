import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:SecTunnel/services/proxy/mobile_proxy_service.dart';

/// Global service to track IP Rotation state across the entire application.
///
/// Refactored from a single global boolean lock to a per-profile [Set]-based
/// approach so that Profile A rotating Modem 1 never blocks Profile B from
/// concurrently rotating Modem 2.
class ModemRotatorService extends ChangeNotifier {
  // Per-profile concurrency: contains profileIds that are currently rotating.
  final Set<String> _rotatingProfiles = {};

  // Per-profile state maps (keyed by profileId).
  final Map<String, String> _profileNames = {};
  final Map<String, bool> _profileLastStatus = {};
  final Map<String, String?> _profileErrors = {};

  // ── Backwards-compatible global getters ─────────────────────────────────

  /// `true` if *any* profile is currently rotating.
  bool get isRotating => _rotatingProfiles.isNotEmpty;

  /// The first profileId currently rotating (or null). Legacy convenience.
  String? get targetProfileId =>
      _rotatingProfiles.isEmpty ? null : _rotatingProfiles.first;

  /// Display name for the first rotating profile. Legacy convenience.
  String? get targetProfileName =>
      targetProfileId == null ? null : _profileNames[targetProfileId];

  /// Last rotation status. Legacy convenience – uses the first rotating profile.
  bool get lastStatus {
    final id = targetProfileId;
    if (id != null) return _profileLastStatus[id] ?? false;
    // After all rotations finish, return the most-recent recorded status.
    return _profileLastStatus.values.lastOrNull ?? false;
  }

  /// Error message for the first rotating profile. Legacy convenience.
  String? get errorMessage =>
      targetProfileId == null ? null : _profileErrors[targetProfileId];

  // ── Per-profile query helpers ────────────────────────────────────────────

  /// Returns `true` if [profileId] is currently in a rotation cycle.
  bool isRotatingProfile(String profileId) =>
      _rotatingProfiles.contains(profileId);

  /// Returns the last rotation outcome for [profileId].
  bool lastStatusForProfile(String profileId) =>
      _profileLastStatus[profileId] ?? false;

  /// Returns the last error (if any) for [profileId].
  String? errorForProfile(String profileId) => _profileErrors[profileId];

  // ── Core rotation logic ──────────────────────────────────────────────────

  /// Trigger IP rotation for a specific [profileId].
  ///
  /// * If [profileId] is already rotating, the call is silently ignored.
  /// * A *different* profileId can rotate concurrently without being blocked.
  Future<void> rotateIp(
    String url,
    String profileId,
    String profileName,
  ) async {
    if (_rotatingProfiles.contains(profileId)) {
      debugPrint(
        '[ModemRotatorService] Profile $profileId ($profileName) is already '
        'rotating. Ignoring duplicate request.',
      );
      return;
    }

    _rotatingProfiles.add(profileId);
    _profileNames[profileId] = profileName;
    _profileErrors[profileId] = null;
    notifyListeners();

    try {
      await MobileProxyService.rotateIp(url);
      _profileLastStatus[profileId] = true;
    } on ProxyRotationException catch (e) {
      _profileLastStatus[profileId] = false;
      _profileErrors[profileId] = e.message;
      debugPrint('[ModemRotatorService] ProxyRotationException rotating $profileId: ${e.message}');
    } catch (e) {
      _profileLastStatus[profileId] = false;
      _profileErrors[profileId] = 'An unexpected rotation error occurred.';
      debugPrint('[ModemRotatorService] Error rotating $profileId: $e');
    } finally {
      _rotatingProfiles.remove(profileId);
      notifyListeners();

      // Keep the result state briefly so the UI can display success/failure,
      // then clean up – but only if the profile has not started rotating again.
      Timer(const Duration(seconds: 3), () {
        if (!_rotatingProfiles.contains(profileId)) {
          _profileNames.remove(profileId);
          _profileErrors.remove(profileId);
          notifyListeners();
        }
      });
    }
  }
}
