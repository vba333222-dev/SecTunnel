import 'dart:convert';

class IntegrityKernel {
  static String generate(Map<String, dynamic> identityJson, String sessionSeed) {
    final identityString = jsonEncode(identityJson);
    return '''
/**
 * SecTunnel IntegrityKernel (Final Hardening Phase)
 * 
 * Philosophy: 
 * - Context Integrity (Workers/Iframes)
 * - Bridge Sanitization (No Flutter/Android Artifacts)
 * - Descriptor Mirroring (Chrome-Native Behavior)
 * - Resolution Coherence (Screen/DPR Mirroring)
 */
(function _() {
    'use strict';
    const scope = (typeof window !== 'undefined' ? window : self);
    
    const MARKER = '__st_active__';
    if (scope[MARKER]) return;
    scope[MARKER] = true;

    const ID = $identityString;

    // --- 0. CLOAKING ENGINE ---
    const cloak = (fn, name) => {
        const nativeToString = Function.prototype.toString;
        const wrapper = function toString() {
            if (this === fn) return `function \${name || fn.name}() { [native code] }`;
            return nativeToString.call(this);
        };
        
        Object.defineProperty(fn, 'toString', {
            value: wrapper,
            configurable: true,
            writable: true,
            enumerable: false
        });
        
        if (name) {
            try { 
                Object.defineProperty(fn, 'name', { value: name, configurable: true }); 
            } catch (e) {}
        }
        return fn;
    };

    const hookDescriptor = (proto, prop, getter, lock = false) => {
        if (!proto) return;
        const name = "get " + prop;
        try {
            Object.defineProperty(proto, prop, {
                get: cloak(getter, name),
                configurable: !lock,
                enumerable: true
            });
        } catch (e) {}
    };

    const maskGlobal = (obj, prop) => {
        if (!obj || !(prop in obj)) return;
        try {
            Object.defineProperty(obj, prop, {
                get: cloak(() => undefined, "get " + prop),
                configurable: false,
                enumerable: false
            });
        } catch (e) {}
    };

    // --- 1. PROPAGATION ---
    const KERNEL_SOURCE = `(\${_.toString()})()`;
    
    const patchWorker = (WorkerClass, name) => {
        if (typeof WorkerClass === 'undefined') return;
        const NativeClass = WorkerClass;
        const NewClass = function(scriptURL, options) {
            let url = scriptURL;
            if (typeof scriptURL === 'string' || (typeof URL !== 'undefined' && scriptURL instanceof URL)) {
                const blob = new Blob([
                    KERNEL_SOURCE + "\\n\\n",
                    "importScripts('" + scriptURL + "');"
                ], { type: 'application/javascript' });
                url = URL.createObjectURL(blob);
            }
            return new NativeClass(url, options);
        };
        NewClass.prototype = NativeClass.prototype;
        scope[name] = cloak(NewClass, name);
    };

    patchWorker(scope.Worker, 'Worker');
    patchWorker(scope.SharedWorker, 'SharedWorker');

    // --- 2. IDENTITY ---
    const navProto = scope.Navigator ? Navigator.prototype : (scope.navigator || {});
    const navHooks = {
        userAgent: () => ID.engine.userAgent,
        platform: () => ID.platform.os === 'Android' ? 'Linux armv8l' : 'Win32',
        deviceMemory: () => ID.hardware.deviceMemory,
        hardwareConcurrency: () => ID.hardware.hardwareConcurrency,
        maxTouchPoints: () => ID.platform.maxTouchPoints || (ID.platform.isMobile ? 5 : 0),
        languages: () => ID.geography.languages || ['en-US', 'en'],
        language: () => ID.geography.locale || 'en-US',
        webdriver: () => false
    };

    for (let key in navHooks) hookDescriptor(navProto, key, navHooks[key], true);

    if (scope.NavigatorUAData) {
        const brands = [
            { brand: 'Not(A:Brand', version: '99' },
            { brand: 'Chromium', version: '124' },
            { brand: 'Google Chrome', version: '124' }
        ];
        hookDescriptor(NavigatorUAData.prototype, 'brands', () => brands, true);
        hookDescriptor(NavigatorUAData.prototype, 'mobile', () => ID.platform.isMobile, true);
        hookDescriptor(NavigatorUAData.prototype, 'platform', () => ID.platform.os, true);

        const nativeGetHighEntropy = NavigatorUAData.prototype.getHighEntropyValues;
        NavigatorUAData.prototype.getHighEntropyValues = cloak(function(hints) {
            return nativeGetHighEntropy.call(this, hints).then(values => {
                const masked = { ...values };
                if (hints.includes('platformVersion')) masked.platformVersion = ID.platform.osVersion || '14.0.0';
                if (hints.includes('model')) masked.model = ID.hardware.cpu.model || '';
                if (hints.includes('uaFullVersion')) masked.uaFullVersion = ID.engine.chromiumVersion || '124.0.0.0';
                return masked;
            });
        }, 'getHighEntropyValues');
    }

    // --- 3. RESOLUTION & SCREEN ---
    const screenHooks = {
        width: () => ID.platform.screen.width,
        height: () => ID.platform.screen.height,
        availWidth: () => ID.platform.screen.width,
        availHeight: () => ID.platform.screen.height,
        colorDepth: () => ID.platform.screen.colorDepth || 24,
        pixelDepth: () => ID.platform.screen.colorDepth || 24,
    };

    if (scope.Screen) {
        for (let key in screenHooks) {
            hookDescriptor(Screen.prototype, key, screenHooks[key], true);
        }
    }

    hookDescriptor(scope, 'devicePixelRatio', () => ID.platform.screen.pixelRatio, true);

    if (scope.VisualViewport) {
        hookDescriptor(VisualViewport.prototype, 'width', () => ID.platform.screen.width, true);
        hookDescriptor(VisualViewport.prototype, 'height', () => ID.platform.screen.height, true);
        hookDescriptor(VisualViewport.prototype, 'scale', () => 1, true);
    }

    // --- 4. WebGL ---
    const patchWebGL = (proto) => {
        if (!proto) return;
        const nativeGetParam = proto.getParameter;
        proto.getParameter = cloak(function(parameter) {
            if (parameter === 0x9245) return ID.hardware.gpu.vendor;
            if (parameter === 0x9246) return ID.hardware.gpu.renderer;
            return nativeGetParam.call(this, parameter);
        }, 'getParameter');
    };

    if (scope.WebGLRenderingContext) patchWebGL(WebGLRenderingContext.prototype);
    if (scope.WebGL2RenderingContext) patchWebGL(WebGL2RenderingContext.prototype);

    // --- 5. IFRAME ---
    if (scope.document) {
        const nativeCreateElement = document.createElement;
        document.createElement = cloak(function(tagName, options) {
            const el = nativeCreateElement.call(document, tagName, options);
            if (tagName && tagName.toLowerCase() === 'iframe') {
                const nativeGet = Object.getOwnPropertyDescriptor(HTMLIFrameElement.prototype, 'contentWindow').get;
                Object.defineProperty(el, 'contentWindow', {
                    get: cloak(function() {
                        const win = nativeGet.call(this);
                        if (win && !win[MARKER]) {
                            try { win.eval(KERNEL_SOURCE); } catch (e) {}
                        }
                        return win;
                    }, 'get contentWindow'),
                    configurable: true
                });
            }
            return el;
        }, 'createElement');
    }

    // --- 6. SANITIZATION ---
    ['external', 'chrome', 'flutter_inappwebview', '_flutter_inappwebview', 'javaInterface', 'android'].forEach(t => maskGlobal(scope, t));
})();
''';
  }
}

