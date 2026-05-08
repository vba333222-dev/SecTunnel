import 'package:sec_tunnel/models/fingerprint_config.dart';
import 'package:sec_tunnel/services/fingerprint/scripts/integrity_kernel.dart';

/// Compatibility Wrapper for IntegrityKernel - Phase 38
/// 
/// This class maintains backward compatibility with components that still use 
/// FingerprintConfig (e.g., StealthAuditScreen) while routing the actual 
/// injection logic to the high-fidelity IntegrityKernel.
class AgroInjector {
  static String generate(FingerprintConfig config) {
    // Map FingerprintConfig to MasterIdentity-like JSON structure for IntegrityKernel
    final identity = {
      'metadata': {
        'label': 'Legacy Wrapped Profile',
      },
      'engine': {
        'name': 'Blink',
        'version': '124',
        'userAgent': config.userAgent,
      },
      'platform': {
        'os': config.os,
        'isMobile': !config.isDesktop,
      },
      'hardware': {
        'deviceMemory': config.deviceMemory,
        'hardwareConcurrency': config.hardwareConcurrency,
        'gpu': {
          'vendor': config.webglConfig.vendor,
          'renderer': config.webglConfig.renderer,
          'extensions': [], // Default empty for legacy
        }
      },
      'geography': {
        'languages': ['en-US', 'en'],
        'locale': 'en-US',
      }
    };

    return IntegrityKernel.generate(identity, config.sessionBoundSeed.toString());
  }
}
