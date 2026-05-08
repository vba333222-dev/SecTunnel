import 'package:sec_tunnel/models/fingerprint_config.dart';

class PermissionsSpoof {
  static String generate(FingerprintConfig config) {
    return '''
    // === PERMISSIONS API SPOOFING ===
    (() => {
      const cloak = self.__pbrowser_cloak;
      if (!window.Permissions || !window.Permissions.prototype.query) return;

      const originalQuery = window.Permissions.prototype.query;
      
      window.Permissions.prototype.query = cloak(function(permissionDescriptor) {
        if (!permissionDescriptor || !permissionDescriptor.name) {
          return originalQuery.apply(this, arguments);
        }

        const name = permissionDescriptor.name;
        
        // Define default states for a "clean" desktop browser
        const desktopStates = {
          'notifications': 'prompt',
          'geolocation': 'prompt',
          'push': 'prompt',
          'midi': 'granted',
          'camera': 'prompt',
          'microphone': 'prompt',
          'background-sync': 'granted',
          'ambient-light-sensor': 'denied',
          'accelerometer': 'granted',
          'gyroscope': 'granted',
          'magnetometer': 'granted',
          'payment-handler': 'denied'
        };

        if (desktopStates[name]) {
          return Promise.resolve({
            name: name,
            state: desktopStates[name],
            onchange: null
          });
        }

        return originalQuery.apply(this, arguments);
      }, 'function query() { [native code] }');
    })();
    ''';
  }
}
