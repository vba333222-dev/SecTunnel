class FunctionCloaker {
  static String get jsCode => r'''
    const _functionToString = Function.prototype.toString;
    const _cloakedFunctions = new WeakMap();

    const _originalToString = Function.prototype.toString;
    
    // Patch Function.prototype.toString globally
    const _spoofedToString = function(...args) {
      if (_cloakedFunctions.has(this)) {
        return _cloakedFunctions.get(this);
      }
      if (this === _spoofedToString) {
        return "function toString() { [native code] }";
      }
      return _originalToString.apply(this, args);
    };
    
    _cloakedFunctions.set(_spoofedToString, "function toString() { [native code] }");
    
    Object.defineProperty(Function.prototype, 'toString', {
      value: _spoofedToString,
      configurable: true,
      enumerable: false,
      writable: true
    });

    function cloakFunction(spoofedFunc, originalFunc) {
      if (originalFunc && originalFunc.name) {
        Object.defineProperty(spoofedFunc, 'name', {
          value: originalFunc.name,
          configurable: true,
          enumerable: false,
          writable: false
        });
      }
      
      if (originalFunc && originalFunc.length !== undefined) {
        Object.defineProperty(spoofedFunc, 'length', {
          value: originalFunc.length,
          configurable: true,
          enumerable: false,
          writable: false
        });
      }
      
      let toStringResult = "function () { [native code] }";
      if (originalFunc) {
        try {
          toStringResult = _originalToString.call(originalFunc);
        } catch (e) {}
      }
      
      _cloakedFunctions.set(spoofedFunc, toStringResult);
      return spoofedFunc;
    }
''';
}
