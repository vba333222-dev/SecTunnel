import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/utils.dart';

/// JavaScript code generator for navigator spoofing
class NavigatorSpoof {
  static String generate(FingerprintConfig config) {
    final userAgent = _escapeJs(config.userAgent);
    final platform = _escapeJs(config.platform);
    final language = _escapeJs(config.language);
    
    return '''
// ===== NAVIGATOR SPOOFING =====
(() => {
  // Advanced Property Descriptor masking to defeat checking mechanisms
  const modifyNavigatorProp = (propName, value) => {
    try {
      if (typeof value === 'function' || typeof value === 'object') {
        Object.defineProperty(Navigator.prototype, propName, {
          get: new Proxy(
            Object.getOwnPropertyDescriptor(Navigator.prototype, propName)?.get || function() { return value; },
            { apply() { return value; } }
          ),
          enumerable: true,
          configurable: true
        });
      } else {
        const spoofedGetter = function() { return value; };
        Object.defineProperty(spoofedGetter, 'name', { value: `get \${propName}`, configurable: true });
        window.__pbrowser_cloak(spoofedGetter, `function get \${propName}() { [native code] }`);
        
        Object.defineProperty(Navigator.prototype, propName, {
          get: spoofedGetter,
          set: undefined,
          enumerable: true,
          configurable: true
        });
      }
    } catch(e){}
  };

  // Mock primary ident properties
  modifyNavigatorProp('userAgent', '\$userAgent');
  modifyNavigatorProp('appVersion', '\$userAgent'.replace('Mozilla/', ''));
  modifyNavigatorProp('platform', '\$platform');
  modifyNavigatorProp('language', '\$language');
  // H-5 fix: languages array must align with language setting
  // e.g. 'id-ID' → ['id-ID', 'id', 'en-US', 'en'] (Chrome Desktop ordering)
  (() => {
    try {
      const lang    = '\$language';
      const base    = lang.split('-')[0];
      const langArr = [lang];
      if (base !== lang) langArr.push(base);
      if (!langArr.includes('en-US')) langArr.push('en-US');
      if (!langArr.includes('en'))    langArr.push('en');
      modifyNavigatorProp('languages', Object.freeze(langArr));
    } catch(e) {}
  })();
  modifyNavigatorProp('hardwareConcurrency', \${config.hardwareConcurrency});
  
  if ('deviceMemory' in navigator) {
    modifyNavigatorProp('deviceMemory', \${config.deviceMemory});
  }

  // M-7 fix: history.length = 1 on fresh WebView is a dead giveaway
  // Spoof to a plausible 2–8 value matching casual desktop browsing
  (() => {
    try {
      const _seed  = ${config.canvasNoiseSalt.hashCode.abs()};
      const _hlen  = 2 + (_seed % 7); // 2–8
      const _histDesc = Object.getOwnPropertyDescriptor(History.prototype, 'length');
      if (_histDesc && _histDesc.get) {
        const _origHLen = _histDesc.get;
        const _spoofHLen = function() {
          const real = _origHLen.call(this);
          return real <= 1 ? _hlen : real;
        };
        window.__pbrowser_cloak(_spoofHLen, 'function get length() { [native code] }');
        Object.defineProperty(History.prototype, 'length', {
          get: _spoofHLen, configurable: true, enumerable: true
        });
      }
    } catch(e) {}
  })();

  // ===== WebDriver Hardening =====
  try {
    const spoofedWebdriverGetter = function() { return false; };
    Object.defineProperty(spoofedWebdriverGetter, 'name', { value: 'get webdriver', configurable: true });
    window.__pbrowser_cloak(spoofedWebdriverGetter, 'function get webdriver() { [native code] }');
    
    Object.defineProperty(Navigator.prototype, 'webdriver', {
      get: spoofedWebdriverGetter,
      set: undefined,
      enumerable: true,
      configurable: true
    });
  } catch(e) {}

  // ===== CHROME MOCK (Anti-Automation) =====
  (() => {
    try {
      if (!window.chrome) {
        const mockChrome = {
          app: {
            isInstalled: false,
            InstallState: {
              DISABLED: 'disabled',
              INSTALLED: 'installed',
              NOT_INSTALLED: 'not_installed'
            },
            RunningState: {
              CANNOT_RUN: 'cannot_run',
              READY_TO_RUN: 'ready_to_run',
              RUNNING: 'running'
            }
          },
          runtime: {
             OnInstalledReason: {
                CHROME_UPDATE: 'chrome_update',
                INSTALL: 'install',
                SHARED_MODULE_UPDATE: 'shared_module_update',
                UPDATE: 'update'
             },
             OnRestartRequiredReason: {
                APP_UPDATE: 'app_update',
                OS_UPDATE: 'os_update',
                PERIODIC: 'periodic'
             },
             PlatformArch: {
                ARM: 'arm',
                ARM64: 'arm64',
                MIPS: 'mips',
                MIPS64: 'mips64',
                X86_32: 'x86-32',
                X86_64: 'x86-64'
             },
             PlatformOs: {
                ANDROID: 'android',
                CROS: 'cros',
                LINUX: 'linux',
                MAC: 'mac',
                OPENBSD: 'openbsd',
                WIN: 'win'
             },
             RequestUpdateCheckStatus: {
                NO_UPDATE: 'no_update',
                THROTTLED: 'throttled',
                UPDATE_AVAILABLE: 'update_available'
             }
          },
          csi: function() { return { startE: Date.now() - 100, onloadT: Date.now(), pageT: 120, onreadyT: 50 }; },
          loadTimes: function() { return { requestTime: Date.now() / 1000, startLoadTime: Date.now() / 1000, commitLoadTime: Date.now() / 1000, finishDocumentLoadTime: Date.now() / 1000, finishLoadTime: Date.now() / 1000, firstPaintTime: Date.now() / 1000, firstPaintAfterLoadTime: 0, navigationType: 'Other', wasFetchedViaSpdy: true, wasNpnNegotiated: true, npnNegotiatedProtocol: 'h2', wasAlternateProtocolAvailable: false, connectionInfo: 'h2' }; }
        };
        
        window.__pbrowser_cloak(mockChrome.csi, 'function csi() { [native code] }');
        window.__pbrowser_cloak(mockChrome.loadTimes, 'function loadTimes() { [native code] }');
        
        Object.defineProperty(window, 'chrome', {
          value: mockChrome,
          writable: false,
          enumerable: true,
          configurable: false
        });
      }
    } catch(e) {}
  })();

  // ===== PERMISSIONS API HARDENING =====
  // Intercepts navigator.permissions.query to gracefully handle ALL Desktop
  // permission names without throwing TypeError/rejection — which is a
  // clear WebView detection signal when asking for Desktop-only permissions.
  (() => {
    try {
      if (!navigator.permissions) return;

      const makeFakePermissionStatus = (name, state) => {
        const ps = Object.create(
          typeof PermissionStatus !== 'undefined' ? PermissionStatus.prototype : Object.prototype
        );
        Object.defineProperty(ps, 'state',  { value: state, enumerable: true, configurable: true });
        Object.defineProperty(ps, 'name',   { value: name,  enumerable: true, configurable: true });
        ps.onchange = null;
        ps.addEventListener    = function() {};
        ps.removeEventListener = function() {};
        return ps;
      };

      // ── Permission name → forced status map ──────────────────────────
      // 'prompt'  = feature exists, user hasn't granted/denied yet (most Desktop defaults)
      // 'granted' = feature is on (background-sync, etc.)
      // 'denied'  = feature is off
      const PERMISSION_TABLE = {
        // Standard permissions — desktop defaults
        'notifications':             'prompt',
        'push':                      'prompt',
        'geolocation':               'prompt',
        'camera':                    'prompt',
        'microphone':                'prompt',
        'speaker-selection':         'prompt',
        'midi':                      'prompt',
        // Clipboard — Desktop Chrome defaults
        'clipboard-read':            'prompt',
        'clipboard-write':           'granted',
        // Screen capture / display APIs
        'display-capture':           'prompt',
        'window-placement':          'prompt',
        'window-management':         'prompt',
        // Local fonts (Desktop-only API)
        'local-fonts':               'prompt',
        // Idle detection (Desktop Chrome)
        'idle-detection':            'prompt',
        // Wake lock
        'screen-wake-lock':          'prompt',
        // Sensors (fine-grained desktop sensors)
        'accelerometer':             'denied',
        'gyroscope':                 'denied',
        'magnetometer':              'denied',
        'ambient-light-sensor':      'denied',
        // Background capabilities
        'background-sync':           'granted',
        'background-fetch':          'prompt',
        'periodic-background-sync':  'denied',
        // Payment / NFC (present but not granted)
        'payment-handler':           'prompt',
        'nfc':                       'denied',
        // Persistent storage
        'persistent-storage':        'granted',
        // Accessibility
        'accessibility-events':      'denied',
      };

      const originalQuery = navigator.permissions.query.bind(navigator.permissions);

      const hardenedQuery = function(parameters) {
        if (!parameters || !parameters.name) {
          return originalQuery(parameters);
        }
        const name = String(parameters.name);

        // If we have a mapped entry — return the fake PermissionStatus
        if (name in PERMISSION_TABLE) {
          const state = PERMISSION_TABLE[name];
          return Promise.resolve(makeFakePermissionStatus(name, state));
        }

        // Unknown permission — gracefully return 'prompt' instead of throwing
        // This prevents TypeError on Desktop-only names unknown to Android WebView
        return originalQuery(parameters).catch(() =>
          Promise.resolve(makeFakePermissionStatus(name, 'prompt'))
        );
      };

      window.__pbrowser_cloak(hardenedQuery, 'function query() { [native code] }');

      try {
        Object.defineProperty(navigator.permissions, 'query', {
          value: hardenedQuery, writable: false, enumerable: true, configurable: true
        });
      } catch(e) {
        navigator.permissions.query = hardenedQuery;
      }

    } catch(e) {}
  })();


  // ===== PLUGINS & MIMETYPES ARRAY FORGERY =====
  // Chrome Desktop always has a "PDF Viewer" plugin. Empty array = red flag.
  (() => {
    try {
      // --- Build MimeType mock objects ---
      const makeMimeType = (type, description, suffixes, plugin) => {
        const mt = Object.create(MimeType.prototype);
        Object.defineProperty(mt, 'type',        { value: type,        enumerable: true, configurable: true });
        Object.defineProperty(mt, 'description', { value: description, enumerable: true, configurable: true });
        Object.defineProperty(mt, 'suffixes',    { value: suffixes,    enumerable: true, configurable: true });
        Object.defineProperty(mt, 'enabledPlugin', { get: () => plugin, enumerable: true, configurable: true });
        return mt;
      };

      // --- Build Plugin mock object ---
      const makePlugin = (name, description, filename, mimeTypes) => {
        const plugin = Object.create(Plugin.prototype);
        Object.defineProperty(plugin, 'name',        { value: name,        enumerable: true, configurable: true });
        Object.defineProperty(plugin, 'description', { value: description, enumerable: true, configurable: true });
        Object.defineProperty(plugin, 'filename',    { value: filename,    enumerable: true, configurable: true });
        Object.defineProperty(plugin, 'length',      { value: mimeTypes.length, enumerable: true, configurable: true });

        // Indexed access
        mimeTypes.forEach((mt, i) => {
          Object.defineProperty(plugin, i, { value: mt, enumerable: true, configurable: true });
        });

        plugin.item = function(i) { return mimeTypes[i] || null; };
        plugin.namedItem = function(name) { return mimeTypes.find(m => m.type === name) || null; };
        window.__pbrowser_cloak(plugin.item,      'function item() { [native code] }');
        window.__pbrowser_cloak(plugin.namedItem, 'function namedItem() { [native code] }');

        plugin[Symbol.iterator] = function*() { for (const mt of mimeTypes) yield mt; };

        return plugin;
      };

      // --- Build PluginArray mock ---
      const makePluginArray = (plugins) => {
        const pa = Object.create(PluginArray.prototype);
        Object.defineProperty(pa, 'length', { value: plugins.length, enumerable: true, configurable: true });

        plugins.forEach((p, i) => {
          Object.defineProperty(pa, i, { value: p, enumerable: true, configurable: true });
          Object.defineProperty(pa, p.name, { value: p, enumerable: true, configurable: true });
        });

        pa.item      = function(i)    { return plugins[i]                            || null; };
        pa.namedItem = function(name) { return plugins.find(p => p.name === name) || null; };
        pa.refresh   = function() {};
        window.__pbrowser_cloak(pa.item,      'function item() { [native code] }');
        window.__pbrowser_cloak(pa.namedItem, 'function namedItem() { [native code] }');
        window.__pbrowser_cloak(pa.refresh,   'function refresh() { [native code] }');

        pa[Symbol.iterator] = function*() { for (const p of plugins) yield p; };

        return pa;
      };

      // --- Build MimeTypeArray mock ---
      const makeMimeTypeArray = (mimeTypes) => {
        const mta = Object.create(MimeTypeArray.prototype);
        Object.defineProperty(mta, 'length', { value: mimeTypes.length, enumerable: true, configurable: true });

        mimeTypes.forEach((mt, i) => {
          Object.defineProperty(mta, i,       { value: mt, enumerable: true, configurable: true });
          Object.defineProperty(mta, mt.type, { value: mt, enumerable: true, configurable: true });
        });

        mta.item      = function(i)    { return mimeTypes[i]                              || null; };
        mta.namedItem = function(type) { return mimeTypes.find(m => m.type === type) || null; };
        window.__pbrowser_cloak(mta.item,      'function item() { [native code] }');
        window.__pbrowser_cloak(mta.namedItem, 'function namedItem() { [native code] }');

        mta[Symbol.iterator] = function*() { for (const mt of mimeTypes) yield mt; };

        return mta;
      };

      // --- Assemble the standard Chrome Desktop plugin set ---
      // Chrome Desktop ships with exactly these two plugin entries (PDF Viewer)
      const pdfPlugin1 = makePlugin(
        'PDF Viewer',
        'Portable Document Format',
        'internal-pdf-viewer',
        [] // MimeTypes added after construction to allow circular ref
      );

      const pdfPlugin2 = makePlugin(
        'Chrome PDF Viewer',
        'Portable Document Format',
        'internal-pdf-viewer',
        []
      );

      const pdfPlugin3 = makePlugin(
        'Chromium PDF Viewer',
        'Portable Document Format',
        'internal-pdf-viewer',
        []
      );

      const pdfPlugin4 = makePlugin(
        'Microsoft Edge PDF Viewer',
        'Portable Document Format',
        'internal-pdf-viewer',
        []
      );

      const pdfPlugin5 = makePlugin(
        'WebKit built-in PDF',
        'Portable Document Format',
        'internal-pdf-viewer',
        []
      );

      // MimeTypes reference their plugin
      const mt1 = makeMimeType('application/pdf',       'Portable Document Format', 'pdf', pdfPlugin1);
      const mt2 = makeMimeType('text/pdf',              'Portable Document Format', 'pdf', pdfPlugin1);

      // Attach mimeTypes to plugins via index + named props (post-construction)
      [pdfPlugin1, pdfPlugin2, pdfPlugin3, pdfPlugin4, pdfPlugin5].forEach(p => {
        Object.defineProperty(p, '0',                   { value: mt1, enumerable: true, configurable: true });
        Object.defineProperty(p, '1',                   { value: mt2, enumerable: true, configurable: true });
        Object.defineProperty(p, 'application/pdf',     { value: mt1, enumerable: true, configurable: true });
        Object.defineProperty(p, 'text/pdf',            { value: mt2, enumerable: true, configurable: true });
        Object.defineProperty(p, 'length',              { value: 2,   enumerable: true, configurable: true });
      });

      const allPlugins   = [pdfPlugin1, pdfPlugin2, pdfPlugin3, pdfPlugin4, pdfPlugin5];
      const allMimeTypes = [mt1, mt2];

      const finalPluginArray   = makePluginArray(allPlugins);
      const finalMimeTypeArray = makeMimeTypeArray(allMimeTypes);

      modifyNavigatorProp('plugins',   finalPluginArray);
      modifyNavigatorProp('mimeTypes', finalMimeTypeArray);

    } catch(e) {}
  })();

  // ===== SCREEN SPOOFING =====
  const modifyScreenProp = (propName, value) => {
    try {
       const getterFn = new Proxy(
         Object.getOwnPropertyDescriptor(Screen.prototype, propName)?.get || function() { return value; },
         { apply() { return value; } }
       );
       
       Object.defineProperty(getterFn, 'name', { value: `get \${propName}`, configurable: true });
       window.__pbrowser_cloak(getterFn, `function get \${propName}() { [native code] }`);
       
       Object.defineProperty(Screen.prototype, propName, {
         get: getterFn,
         set: undefined,
         enumerable: true,
         configurable: true
       });
    } catch(e) {}
  };

  modifyScreenProp('width', \${config.screenResolution.width});
  modifyScreenProp('height', \${config.screenResolution.height});
  modifyScreenProp('availWidth', \${config.screenResolution.width});
  modifyScreenProp('availHeight', \${config.screenResolution.height - 40});
  modifyScreenProp('colorDepth', \${config.screenResolution.colorDepth});
  modifyScreenProp('pixelDepth', \${config.screenResolution.colorDepth});

})();
''';
  }
  
  static String _escapeJs(String str) {
    return str
        .replaceAll('\\\\', '\\\\\\\\')
        .replaceAll("'", "\\\\'")
        .replaceAll('"', '\\\\"')
        .replaceAll('\\n', '\\\\n')
        .replaceAll('\\r', '\\\\r');
  }
}

