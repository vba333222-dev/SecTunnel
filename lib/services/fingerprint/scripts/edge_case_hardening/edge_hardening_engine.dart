import 'plugins_patch.dart';
import 'permissions_patch.dart';
import 'media_devices_patch.dart';
import 'error_stack_patch.dart';
import 'connection_patch.dart';

class EdgeHardeningEngine {
  static String getPayload() {
    return '''
      (function applyEdgeHardening() {
        try {
          \${${ErrorStackPatch.getJS()}}
          \${${PluginsPatch.getJS()}}
          \${${PermissionsPatch.getJS()}}
          \${${MediaDevicesPatch.getJS()}}
          \${${ConnectionPatch.getJS()}}
          
          if (window.console && window.console.debug) {
            // [EDGE] Logging for debug purposes only
            // console.debug("[EDGE] Edge Case Hardening applied successfully.");
          }
        } catch (e) {
          // Silent failure protection
        }
      })();
    ''';
  }
}
