import 'package:pbrowser/models/fingerprint_config.dart';

/// Spoofs the JavaScript Intl (Internationalization) API.
/// This intercepts `Intl.DateTimeFormat`, `Intl.NumberFormat`, `Intl.RelativeTimeFormat`, 
/// and `Intl.PluralRules` to enforce the profile's configured timezone and locale.
/// This prevents trackers using `resolvedOptions().timeZone` from bypassing the Date spoof,
/// and prevents trackers from identifying the Android ICU engine via specific numeric grouping rules.
class IntlApiSpoof {
  static String generate(FingerprintConfig config) {
    const defaultLocale = 'en-US'; 
    final locale = config.language.isNotEmpty ? config.language : defaultLocale;
    final timezone = config.timezone;

    return '''
// === INTL API (LOCALE & TIMEZONE) SPOOFING ===
(() => {
  try {
    const spoofedLocale = '$locale';
    const spoofedTimezone = '$timezone';

    if (typeof Intl === 'undefined') return;

    // Helper: Safely merge user options with our forced spoofed options
    const mergeOptions = (userOpts, isDate = false) => {
      const opts = userOpts ? Object.assign({}, userOpts) : {};
      
      // Always force locale matching (Intl handles locale matching via the constructor argument primarily, 
      // but some options like numberingSystem might leak Android defaults if not careful. We leave them mostly native
      // unless we need strict overrides).
      
      if (isDate) {
         // Force timezone
         opts.timeZone = spoofedTimezone;
      }
      return opts;
    };

    // Helper: Hook an Intl constructor
    const hookIntlConstructor = (ConstructorName, isDate = false) => {
      const OrigConstructor = Intl[ConstructorName];
      if (!OrigConstructor) return;

      const spoofedConstructor = new Proxy(OrigConstructor, {
        construct(target, args) {
          // args[0] is locales, args[1] is options
          const requestedLocales = args[0] !== undefined ? args[0] : spoofedLocale;
          // Force our locale if none provided, or if they tried to use 'default'
          const finalLocales = (requestedLocales === undefined || requestedLocales === 'default') ? spoofedLocale : requestedLocales;
          
          const userOptions = args[1];
          const finalOptions = mergeOptions(userOptions, isDate);

          const instance = new target(finalLocales, finalOptions);

          // Hook resolvedOptions() to lie about what was actually resolved
          if (instance.resolvedOptions) {
            const origResolved = instance.resolvedOptions.bind(instance);
            instance.resolvedOptions = function() {
              const res = origResolved();
              res.locale = spoofedLocale;
              if (isDate) res.timeZone = spoofedTimezone;
              return res;
            };
            self.__pbrowser_cloak(instance.resolvedOptions, 'function resolvedOptions() { [native code] }');
          }

          // If it's a NumberFormat, we might want to intercept format() to ensure 
          // thousands separators look like Desktop Chrome rather than Android ICU.
          // For now, forcing the locale parameter is usually sufficient to sync the ICU output,
          // but we wrap format just in case advanced formatting is needed later.
          if (ConstructorName === 'NumberFormat' && instance.format) {
             const origFormat = instance.format.bind(instance);
             instance.format = function(value) {
                return origFormat(value);
             };
             self.__pbrowser_cloak(instance.format, 'function format() { [native code] }');
          }

          return instance;
        },
        apply(target, thisArg, args) {
          // Built-in Intl constructors can be called without 'new'
          const requestedLocales = args[0] !== undefined ? args[0] : spoofedLocale;
          const finalLocales = (requestedLocales === undefined || requestedLocales === 'default') ? spoofedLocale : requestedLocales;
          const finalOptions = mergeOptions(args[1], isDate);
          
          const instance = Reflect.apply(target, thisArg, [finalLocales, finalOptions]);
          
          // Must duplicate the resolvedOptions hook for the function call version
          if (instance && instance.resolvedOptions) {
            const origResolved = instance.resolvedOptions.bind(instance);
            instance.resolvedOptions = function() {
              const res = origResolved();
              res.locale = spoofedLocale;
              if (isDate) res.timeZone = spoofedTimezone;
              return res;
            };
            self.__pbrowser_cloak(instance.resolvedOptions, 'function resolvedOptions() { [native code] }');
          }
          
          return instance;
        }
      });

      self.__pbrowser_cloak(spoofedConstructor, `function \${ConstructorName}() { [native code] }`);
      Intl[ConstructorName] = spoofedConstructor;
    };

    // Apply hooks
    hookIntlConstructor('DateTimeFormat', true);
    hookIntlConstructor('NumberFormat', false);
    hookIntlConstructor('RelativeTimeFormat', false);
    hookIntlConstructor('PluralRules', false);
    hookIntlConstructor('Collator', false);
    hookIntlConstructor('ListFormat', false);
    
    // Also protect Intl.DateTimeFormat.supportedLocalesOf etc if sophisticated sweeps occur
    const hookSupportedLocales = (ConstructorName) => {
        if (!Intl[ConstructorName] || !Intl[ConstructorName].supportedLocalesOf) return;
        const orig = Intl[ConstructorName].supportedLocalesOf;
        const spoofed = function(locales, options) {
            return orig.call(this, locales || spoofedLocale, options);
        };
        self.__pbrowser_cloak(spoofed, 'function supportedLocalesOf() { [native code] }');
        Intl[ConstructorName].supportedLocalesOf = spoofed;
    };

    hookSupportedLocales('DateTimeFormat');
    hookSupportedLocales('NumberFormat');
    hookSupportedLocales('Collator');

    // 2. Intercept Date locale strings to use the spoofed locale/timezone directly
    const hookDateLocaleFunc = (methodName) => {
        const orig = Date.prototype[methodName];
        if (!orig) return;
        const spoofed = function(locales, options) {
            const finalLocales = locales || spoofedLocale;
            const finalOpts = mergeOptions(options, true);
            return orig.call(this, finalLocales, finalOpts);
        };
        self.__pbrowser_cloak(spoofed, `function \${methodName}() { [native code] }`);
        Date.prototype[methodName] = spoofed;
    };

    hookDateLocaleFunc('toLocaleString');
    hookDateLocaleFunc('toLocaleDateString');
    hookDateLocaleFunc('toLocaleTimeString');

  } catch(e) {}
})();
''';
  }
}
