import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pbrowser/services/proxy/mobile_proxy_service.dart';

/// Global service to track IP Rotation state across the entire application.
class ModemRotatorService extends ChangeNotifier {
  bool _isRotating = false;
  String? _targetProfileId;
  String? _targetProfileName;
  bool _lastStatus = false;
  String? _errorMessage;

  bool get isRotating => _isRotating;
  String? get targetProfileId => _targetProfileId;
  String? get targetProfileName => _targetProfileName;
  bool get lastStatus => _lastStatus;
  String? get errorMessage => _errorMessage;

  /// Trigger rotation globally
  Future<void> rotateIp(String url, String profileId, String profileName) async {
    if (_isRotating) {
      debugPrint('[ModemRotatorService] Already rotating another proxy. Ignoring request.');
      return;
    }

    _isRotating = true;
    _targetProfileId = profileId;
    _targetProfileName = profileName;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastStatus = await MobileProxyService.rotateIp(url);
    } catch (e) {
      _lastStatus = false;
      _errorMessage = e.toString();
    } finally {
      _isRotating = false;
      notifyListeners();

      // Clear the target profile after a short delay so the UI can show success/failure state briefly
      Timer(const Duration(seconds: 3), () {
        if (!_isRotating) { // Only clear if a new one hasn't started
          _targetProfileId = null;
          _targetProfileName = null;
          _errorMessage = null;
          notifyListeners();
        }
      });
    }
  }
}
