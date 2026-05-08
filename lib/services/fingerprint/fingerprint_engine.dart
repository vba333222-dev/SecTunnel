import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:sec_tunnel/models/identity/master_identity.dart';
import 'package:sec_tunnel/services/fingerprint/validation/identity_validator.dart';
import 'package:sec_tunnel/services/fingerprint/capabilities/capability_matrix.dart';
import 'package:sec_tunnel/services/fingerprint/scripts/integrity_kernel.dart';
import 'package:sec_tunnel/core/logging/logger.dart';

class FingerprintEngine {
  final MasterIdentity identity;
  final CapabilityMatrix capabilityMatrix;
  final AppLogger _log = AppLogger.instance;

  FingerprintEngine(this.identity) : capabilityMatrix = CapabilityMatrix(identity);

  /// Initializes the engine, validating the identity first.
  void initialize() {
    final validation = IdentityValidator.validate(identity);
    if (!validation.isValid) {
      _log.error(LogTag.system, '[FINGERPRINT ENGINE] Identity Validation Failed: \${validation.errors.join(", ")}');
      throw Exception('Inconsistent Browser Identity Detected');
    }
    _log.info(LogTag.system, '[FINGERPRINT ENGINE] Identity Initialized: \${identity.metadata.label}');
  }

  /// Generates the UserScripts for InAppWebView injection.
  List<UserScript> generateUserScripts() {
    final jsPayload = IntegrityKernel.generate(identity.toJson(), identity.sessionSeed);
    
    return [
      UserScript(
        source: jsPayload,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        forMainFrameOnly: false,
      )
    ];
  }
}
