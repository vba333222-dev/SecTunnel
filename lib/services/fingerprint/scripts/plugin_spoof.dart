import 'package:sec_tunnel/models/fingerprint_config.dart';

class PluginSpoof {
  static String generate(FingerprintConfig config) {
    if (!config.isDesktop) return '';

    return '''
    // === PLUGIN & MIME-TYPE SPOOFING ===
    (() => {
      const cloak = self.__pbrowser_cloak;
      
      function createPlugin(name, filename, description, mimeTypes) {
        const plugin = Object.create(Plugin.prototype);
        Object.defineProperties(plugin, {
          name: { value: name, enumerable: true },
          filename: { value: filename, enumerable: true },
          description: { value: description, enumerable: true },
          length: { value: mimeTypes.length, enumerable: true }
        });
        
        mimeTypes.forEach((m, i) => {
          const mt = Object.create(MimeType.prototype);
          Object.defineProperties(mt, {
            type: { value: m.type, enumerable: true },
            description: { value: m.description, enumerable: true },
            suffixes: { value: m.suffixes, enumerable: true },
            enabledPlugin: { value: plugin, enumerable: true }
          });
          Object.defineProperty(plugin, i, { value: mt, enumerable: true });
          Object.defineProperty(plugin, m.type, { value: mt, enumerable: false });
        });
        
        return plugin;
      }

      const pluginsData = [
        {
          name: 'PDF Viewer',
          filename: 'internal-pdf-viewer',
          description: 'Portable Document Format',
          mimes: [{ type: 'application/pdf', description: 'Portable Document Format', suffixes: 'pdf' }]
        },
        {
          name: 'Chrome PDF Viewer',
          filename: 'internal-pdf-viewer',
          description: 'Google Chrome PDF Viewer',
          mimes: [{ type: 'application/pdf', description: 'Portable Document Format', suffixes: 'pdf' }]
        },
        {
          name: 'Chromium PDF Viewer',
          filename: 'internal-pdf-viewer',
          description: 'Chromium PDF Viewer',
          mimes: [{ type: 'application/pdf', description: 'Portable Document Format', suffixes: 'pdf' }]
        },
        {
          name: 'Microsoft Edge PDF Viewer',
          filename: 'internal-pdf-viewer',
          description: 'Microsoft Edge PDF Viewer',
          mimes: [{ type: 'application/pdf', description: 'Portable Document Format', suffixes: 'pdf' }]
        },
        {
          name: 'WebKit built-in PDF',
          filename: 'internal-pdf-viewer',
          description: 'WebKit built-in PDF',
          mimes: [{ type: 'application/pdf', description: 'Portable Document Format', suffixes: 'pdf' }]
        }
      ];

      const mockPlugins = pluginsData.map(p => createPlugin(p.name, p.filename, p.description, p.mimes));
      
      const pluginArray = Object.create(PluginArray.prototype);
      Object.defineProperty(pluginArray, 'length', { value: mockPlugins.length, enumerable: true });
      mockPlugins.forEach((p, i) => {
        Object.defineProperty(pluginArray, i, { value: p, enumerable: true });
        Object.defineProperty(pluginArray, p.name, { value: p, enumerable: false });
      });

      const mimeTypeArray = Object.create(MimeTypeArray.prototype);
      const allMimes = mockPlugins.flatMap(p => Array.from({length: p.length}, (_, i) => p[i]));
      Object.defineProperty(mimeTypeArray, 'length', { value: allMimes.length, enumerable: true });
      allMimes.forEach((m, i) => {
        Object.defineProperty(mimeTypeArray, i, { value: m, enumerable: true });
        Object.defineProperty(mimeTypeArray, m.type, { value: m, enumerable: false });
      });

      // Override navigator properties
      Object.defineProperty(Navigator.prototype, 'plugins', {
        get: cloak(function() { return pluginArray; }, 'function get plugins() { [native code] }'),
        enumerable: true, configurable: true
      });
      
      Object.defineProperty(Navigator.prototype, 'mimeTypes', {
        get: cloak(function() { return mimeTypeArray; }, 'function get mimeTypes() { [native code] }'),
        enumerable: true, configurable: true
      });

      // Refresh function
      Navigator.prototype.refresh = cloak(function() {}, 'function refresh() { [native code] }');

    })();
    ''';
  }
}
